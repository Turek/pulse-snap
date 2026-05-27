import '../../data/database/app_database.dart';
import '../tags/reading_with_tags.dart';

abstract class IReadingRepository {
  Future<void> saveReading(Reading reading, {List<String> tags = const []});
  Future<void> updateReading(Reading reading, {List<String> tags = const []});
  Future<void> deleteReading(int id);
  Future<ReadingWithTags?> getReadingWithTags(int id);
  Stream<List<ReadingWithTags>> watchAllReadingsWithTags();
  Future<List<ReadingWithTags>> getReadingsByTag(String tag);
  Future<List<String>> getAllUsedTags();

  /// Writes every locally-stored reading that has not yet been synced to the
  /// system health platform. Skips readings that already have a sync record so
  /// it is safe to run repeatedly. Returns the number of readings synced.
  Future<int> backfillToHealthPlatform();
}
