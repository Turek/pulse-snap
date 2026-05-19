import '../tags/reading_with_tags.dart';

/// Platform-agnostic interface for writing readings to a system health store
/// (Apple Health on iOS, Health Connect on Android). Phase 4 is write-only;
/// reads + deduplication come later (see Docs/pulsesnap-tech-spec-updates.md
/// §Rollout order).
abstract class IHealthPlatformService {
  /// True if the underlying SDK is installed/available on this device.
  Future<bool> isAvailable();

  /// Triggers the platform's permission prompt for the WRITE scope only.
  /// Returns true if all requested writes were granted.
  Future<bool> requestWritePermissions();

  /// Returns true when the app currently has write permissions for the
  /// blood-pressure + heart-rate types it needs.
  Future<bool> hasWritePermissions();

  /// Writes one reading. Returns an opaque external id (used as the
  /// `ExternalSyncRecord.externalId`) on success, or null on failure /
  /// when the reading had nothing to write.
  Future<String?> writeReading(ReadingWithTags reading);

  /// Best-effort revoke. On iOS this is a no-op (the system does not allow
  /// programmatic revocation); on Android it calls `revokePermissions`.
  Future<void> disconnect();
}
