import 'package:drift/drift.dart';

import '../../domain/repositories/i_reading_repository.dart';
import '../../domain/tags/reading_with_tags.dart';
import '../database/app_database.dart';

class ReadingRepository implements IReadingRepository {
  final AppDatabase _db;
  ReadingRepository(this._db);

  @override
  Future<void> saveReading(
    Reading reading, {
    List<String> tags = const [],
  }) {
    return _db.transaction(() async {
      // id <= 0 means "new row" — let SQLite assign the id.
      final companion = reading.id <= 0
          ? reading.toCompanion(true).copyWith(id: const Value.absent())
          : reading.toCompanion(true);
      final id = await _db.into(_db.readings).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );
      final readingId = reading.id <= 0 ? id : reading.id;
      // Replace tag set for this reading.
      await (_db.delete(_db.readingTags)
            ..where((t) => t.readingId.equals(readingId)))
          .go();
      for (final tag in _dedupe(tags)) {
        await _db.into(_db.readingTags).insert(
              ReadingTagsCompanion.insert(
                readingId: readingId,
                value: tag,
              ),
            );
      }
    });
  }

  @override
  Future<void> updateReading(
    Reading reading, {
    List<String> tags = const [],
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.readings)..where((t) => t.id.equals(reading.id)))
          .write(reading.toCompanion(true));
      await (_db.delete(_db.readingTags)
            ..where((t) => t.readingId.equals(reading.id)))
          .go();
      for (final tag in _dedupe(tags)) {
        await _db.into(_db.readingTags).insert(
              ReadingTagsCompanion.insert(
                readingId: reading.id,
                value: tag,
              ),
            );
      }
    });
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
