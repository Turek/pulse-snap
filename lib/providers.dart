import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/app_database.dart';
import 'data/health_platform/health_plus_service.dart';
import 'data/repositories/reading_repository.dart';
import 'domain/health_platform/health_platform_service.dart';
import 'domain/repositories/i_reading_repository.dart';
import 'domain/scanner/scan_orchestrator.dart';
import 'domain/tags/reading_with_tags.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final healthPlatformServiceProvider = Provider<IHealthPlatformService>((ref) {
  return HealthPlusService();
});

final readingRepositoryProvider = Provider<IReadingRepository>((ref) {
  return ReadingRepository(
    ref.watch(appDatabaseProvider),
    healthPlatformService: ref.watch(healthPlatformServiceProvider),
  );
});

final scanOrchestratorProvider = Provider<ScanOrchestrator>((ref) {
  final orch = ScanOrchestrator.mvp();
  ref.onDispose(orch.dispose);
  return orch;
});

final readingsProvider = StreamProvider<List<ReadingWithTags>>((ref) {
  return ref.watch(readingRepositoryProvider).watchAllReadingsWithTags();
});

final latestReadingProvider = FutureProvider<ReadingWithTags?>((ref) async {
  final list = await ref.watch(readingsProvider.future);
  if (list.isEmpty) return null;
  return list.first;
});
