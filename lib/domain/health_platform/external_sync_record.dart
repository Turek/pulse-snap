import 'reading_source_type.dart';

class ExternalSyncRecord {
  final int readingId;
  final ReadingSourceType sourceType;
  final String externalId;
  final DateTime syncedAt;
  final String platform; // apple_health | health_connect

  const ExternalSyncRecord({
    required this.readingId,
    required this.sourceType,
    required this.externalId,
    required this.syncedAt,
    required this.platform,
  });
}
