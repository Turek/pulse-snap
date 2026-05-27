import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../domain/health_platform/health_platform_service.dart';
import '../../domain/health_platform/reading_source_type.dart';
import '../../domain/repositories/i_reading_repository.dart';
import '../../domain/tags/reading_with_tags.dart';
import '../database/app_database.dart';
import '../health_platform/health_plus_service.dart';

class ReadingRepository implements IReadingRepository {
  final AppDatabase _db;
  final IHealthPlatformService? _health;
  ReadingRepository(this._db, {IHealthPlatformService? healthPlatformService})
      : _health = healthPlatformService;

  @override
  Future<void> saveReading(
    Reading reading, {
    List<String> tags = const [],
  }) async {
    final dedupedTags = _dedupe(tags);
    final readingId = await _db.transaction(() async {
      // id <= 0 means "new row" — let SQLite assign the id.
      final companion = reading.id <= 0
          ? reading.toCompanion(true).copyWith(id: const Value.absent())
          : reading.toCompanion(true);
      final id = await _db.into(_db.readings).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );
      final newId = reading.id <= 0 ? id : reading.id;
      // Replace tag set for this reading.
      await (_db.delete(_db.readingTags)
            ..where((t) => t.readingId.equals(newId)))
          .go();
      for (final tag in dedupedTags) {
        await _db.into(_db.readingTags).insert(
              ReadingTagsCompanion.insert(
                readingId: newId,
                value: tag,
              ),
            );
      }
      return newId;
    });
    unawaited(_syncToHealthPlatform(readingId, dedupedTags));
  }

  @override
  Future<void> updateReading(
    Reading reading, {
    List<String> tags = const [],
  }) async {
    final dedupedTags = _dedupe(tags);
    await _db.transaction(() async {
      await (_db.update(_db.readings)..where((t) => t.id.equals(reading.id)))
          .write(reading.toCompanion(true));
      await (_db.delete(_db.readingTags)
            ..where((t) => t.readingId.equals(reading.id)))
          .go();
      for (final tag in dedupedTags) {
        await _db.into(_db.readingTags).insert(
              ReadingTagsCompanion.insert(
                readingId: reading.id,
                value: tag,
              ),
            );
      }
    });
    unawaited(_syncToHealthPlatform(reading.id, dedupedTags));
  }

  /// Fire-and-forget write to the system health platform. Wrapped in a
  /// try/catch so a sync failure can never block a local save.
  Future<void> _syncToHealthPlatform(int readingId, List<String> tags) async {
    final svc = _health;
    if (svc == null) return;
    try {
      if (!await svc.hasWritePermissions()) return;
      final reading = await (_db.select(_db.readings)
            ..where((t) => t.id.equals(readingId)))
          .getSingleOrNull();
      if (reading == null) return;
      final externalId = await svc.writeReading(
        ReadingWithTags(reading: reading, tags: tags),
      );
      if (externalId == null) return;
      await _db.into(_db.externalSyncRecords).insert(
            ExternalSyncRecordsCompanion.insert(
              readingId: readingId,
              sourceType: _exportSourceType().name,
              externalId: externalId,
              platform: currentHealthPlatformName(),
            ),
          );
    } catch (e, st) {
      debugPrint('Health-platform sync failed for reading $readingId: $e\n$st');
    }
  }

  @override
  Future<int> backfillToHealthPlatform() async {
    final svc = _health;
    if (svc == null) return 0;
    if (!await svc.hasWritePermissions()) return 0;

    // Readings that already have a sync record are skipped, so re-running is
    // safe and never produces duplicates in the health platform.
    final synced = await _db.select(_db.externalSyncRecords).get();
    final syncedIds = synced.map((r) => r.readingId).toSet();

    final readings = await (_db.select(_db.readings)
          ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
        .get();

    final pending = readings.where((r) => !syncedIds.contains(r.id)).toList();
    final tagsById = await _tagsFor(pending.map((r) => r.id).toList());

    var count = 0;
    for (final reading in pending) {
      try {
        final tags = tagsById[reading.id] ?? const [];
        final externalId = await svc.writeReading(
          ReadingWithTags(reading: reading, tags: tags),
        );
        if (externalId == null) continue;
        await _db.into(_db.externalSyncRecords).insert(
              ExternalSyncRecordsCompanion.insert(
                readingId: reading.id,
                sourceType: _exportSourceType().name,
                externalId: externalId,
                platform: currentHealthPlatformName(),
              ),
            );
        count++;
      } catch (e, st) {
        debugPrint('Backfill sync failed for reading ${reading.id}: $e\n$st');
      }
    }
    return count;
  }

  static ReadingSourceType _exportSourceType() {
    final name = currentHealthPlatformName();
    return name == 'apple_health'
        ? ReadingSourceType.appleHealthExport
        : ReadingSourceType.healthConnectExport;
  }

  @override
  Future<void> deleteReading(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.readingTags)..where((t) => t.readingId.equals(id)))
          .go();
      await (_db.delete(_db.readings)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<ReadingWithTags?> getReadingWithTags(int id) async {
    final reading = await (_db.select(_db.readings)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (reading == null) return null;
    final tags = await _tagsFor([id]);
    return ReadingWithTags(
      reading: reading,
      tags: tags[id] ?? const [],
    );
  }

  @override
  Stream<List<ReadingWithTags>> watchAllReadingsWithTags() {
    final readingsStream = (_db.select(_db.readings)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .watch();
    return readingsStream.asyncMap((readings) async {
      if (readings.isEmpty) return const <ReadingWithTags>[];
      final tagsByReading = await _tagsFor(readings.map((r) => r.id).toList());
      return readings
          .map((r) => ReadingWithTags(
                reading: r,
                tags: tagsByReading[r.id] ?? const [],
              ))
          .toList();
    });
  }

  @override
  Future<List<ReadingWithTags>> getReadingsByTag(String tag) async {
    final lower = tag.toLowerCase();
    final matched = await (_db.select(_db.readingTags)
          ..where((t) => t.value.lower().equals(lower)))
        .get();
    final readingIds = matched.map((t) => t.readingId).toSet().toList();
    if (readingIds.isEmpty) return const [];
    final readings = await (_db.select(_db.readings)
          ..where((t) => t.id.isIn(readingIds))
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .get();
    final tagsByReading = await _tagsFor(readingIds);
    return readings
        .map((r) => ReadingWithTags(
              reading: r,
              tags: tagsByReading[r.id] ?? const [],
            ))
        .toList();
  }

  @override
  Future<List<String>> getAllUsedTags() async {
    final rows = await _db.select(_db.readingTags).get();
    final seen = <String, String>{};
    for (final r in rows) {
      final key = r.value.toLowerCase();
      seen.putIfAbsent(key, () => r.value);
    }
    final out = seen.values.toList()..sort();
    return out;
  }

  Future<Map<int, List<String>>> _tagsFor(List<int> readingIds) async {
    if (readingIds.isEmpty) return const {};
    final rows = await (_db.select(_db.readingTags)
          ..where((t) => t.readingId.isIn(readingIds))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final out = <int, List<String>>{};
    for (final r in rows) {
      (out[r.readingId] ??= []).add(r.value);
    }
    return out;
  }

  static List<String> _dedupe(List<String> tags) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in tags) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) out.add(trimmed);
    }
    return out;
  }
}
