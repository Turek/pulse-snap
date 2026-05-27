import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../../domain/health_platform/health_platform_service.dart';
import '../../domain/tags/reading_with_tags.dart';

/// Thin wrapper around the `health` package that the tests can swap for a fake.
/// The real production wrapper just forwards to a singleton [Health] instance.
class HealthFacade {
  final Health _health;
  bool _configured = false;

  HealthFacade([Health? health]) : _health = health ?? Health();

  Future<void> ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) =>
      _health.hasPermissions(types, permissions: permissions);

  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) =>
      _health.requestAuthorization(types, permissions: permissions);

  Future<bool> writeHealthData({
    required double value,
    required HealthDataType type,
    required DateTime startTime,
    String? clientRecordId,
    DateTime? endTime,
    RecordingMethod recordingMethod = RecordingMethod.manual,
  }) =>
      _health.writeHealthData(
        value: value,
        type: type,
        startTime: startTime,
        clientRecordId: clientRecordId,
        endTime: endTime,
        recordingMethod: recordingMethod,
      );

  Future<void> revokePermissions() => _health.revokePermissions();

  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() =>
      _health.getHealthConnectSdkStatus();

  Future<bool> writeBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime startTime,
    String? clientRecordId,
    RecordingMethod recordingMethod = RecordingMethod.manual,
  }) =>
      _health.writeBloodPressure(
        systolic: systolic,
        diastolic: diastolic,
        startTime: startTime,
        clientRecordId: clientRecordId,
        recordingMethod: recordingMethod,
      );
}

/// Platform name persisted in `ExternalSyncRecord.platform`.
String currentHealthPlatformName() =>
    Platform.isIOS ? 'apple_health' : 'health_connect';

class HealthPlusService implements IHealthPlatformService {
  static const _types = <HealthDataType>[
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.HEART_RATE,
  ];

  // WRITE for every type — read flow is deferred to a later phase.
  static const _writePermissions = <HealthDataAccess>[
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
  ];

  final HealthFacade _facade;
  final Uuid _uuid;

  HealthPlusService({HealthFacade? facade, Uuid? uuid})
      : _facade = facade ?? HealthFacade(),
        _uuid = uuid ?? const Uuid();

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      await _facade.ensureConfigured();
      if (Platform.isAndroid) {
        // On Android, "available" means the Health Connect provider is actually
        // usable. A status of sdkUnavailableProviderUpdateRequired/unavailable
        // is what lists the app under "Needs updating" and makes grants return
        // empty, so the UI must treat those as not-available.
        final status = await _facade.getHealthConnectSdkStatus();
        debugPrint('PulseSnap: HealthConnect SDK status = $status');
        return status == HealthConnectSdkStatus.sdkAvailable;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestWritePermissions() async {
    await _facade.ensureConfigured();
    return _facade.requestAuthorization(_types, permissions: _writePermissions);
  }

  @override
  Future<bool> hasWritePermissions() async {
    await _facade.ensureConfigured();
    // iOS may return null for WRITE checks; treat null as "unknown -> false"
    // so we never try to write without an explicit grant.
    final granted =
        await _facade.hasPermissions(_types, permissions: _writePermissions);
    return granted == true;
  }

  @override
  Future<String?> writeReading(ReadingWithTags reading) async {
    final r = reading.reading;
    final ts = r.measuredAt;
    var attempted = false;
    var allOk = true;

    await _facade.ensureConfigured();

    if (r.systolic != null && r.diastolic != null) {
      // Health Connect stores blood pressure as a single BloodPressureRecord —
      // systolic and diastolic must be written together. Writing them as
      // separate data points does not produce a valid BP record on Android.
      // A stable clientRecordId makes the write an idempotent upsert, so a
      // re-sync of the same reading updates rather than duplicates.
      attempted = true;
      final bpOk = await _facade.writeBloodPressure(
        systolic: r.systolic!,
        diastolic: r.diastolic!,
        startTime: ts,
        clientRecordId: 'pulsesnap-bp-${r.id}',
      );
      allOk = allOk && bpOk;
    }

    if (r.pulse != null) {
      attempted = true;
      final hrOk = await _facade.writeHealthData(
        value: r.pulse!.toDouble(),
        type: HealthDataType.HEART_RATE,
        startTime: ts,
        clientRecordId: 'pulsesnap-hr-${r.id}',
      );
      allOk = allOk && hrOk;
    }

    // Only report success when the whole reading was written. A partial
    // failure returns null so it is not recorded as synced and gets retried
    // (the idempotent clientRecordIds make the retry safe).
    if (!attempted || !allOk) return null;
    // The `health` package does not surface a stable external id, so we
    // synthesize one to persist in ExternalSyncRecord.
    return _uuid.v4();
  }

  @override
  Future<void> disconnect() async {
    if (Platform.isAndroid) {
      await _facade.ensureConfigured();
      await _facade.revokePermissions();
    }
    // iOS: no programmatic revocation available.
  }
}
