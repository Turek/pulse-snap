import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/health_platform/health_plus_service.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';

class _FakeHealthFacade extends HealthFacade {
  final List<_Write> writes = [];
  bool granted = true;
  bool hrWriteOk = true;

  _FakeHealthFacade() : super();

  @override
  Future<void> ensureConfigured() async {}

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      granted;

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      granted;

  @override
  Future<bool> writeHealthData({
    required double value,
    required HealthDataType type,
    required DateTime startTime,
    String? clientRecordId,
    DateTime? endTime,
    RecordingMethod recordingMethod = RecordingMethod.manual,
  }) async {
    writes.add(_Write(type, value, startTime, clientRecordId));
    return hrWriteOk;
  }

  @override
  Future<bool> writeBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime startTime,
    String? clientRecordId,
    RecordingMethod recordingMethod = RecordingMethod.manual,
  }) async {
    bpWrites.add(_BpWrite(systolic, diastolic, startTime, clientRecordId));
    return true;
  }

  final List<_BpWrite> bpWrites = [];

  @override
  Future<void> revokePermissions() async {}
}

class _Write {
  final HealthDataType type;
  final double value;
  final DateTime startTime;
  final String? clientRecordId;
  _Write(this.type, this.value, this.startTime, this.clientRecordId);
}

class _BpWrite {
  final int systolic;
  final int diastolic;
  final DateTime startTime;
  final String? clientRecordId;
  _BpWrite(this.systolic, this.diastolic, this.startTime, this.clientRecordId);
}

ReadingWithTags _r({
  int? sys = 128,
  int? dia = 82,
  int? pulse = 70,
  DateTime? at,
}) {
  final ts = at ?? DateTime(2026, 5, 18, 9, 30);
  return ReadingWithTags(
    reading: Reading(
      id: 1,
      userId: 'default',
      measuredAt: ts,
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      sourceType: ScannerType.mlKit,
      isManuallyEdited: false,
      createdAt: ts,
    ),
    tags: const [],
  );
}

void main() {
  test('writeReading sends BP as one record + HR with measuredAt timestamp',
      () async {
    final fake = _FakeHealthFacade();
    final svc = HealthPlusService(facade: fake);
    final reading = _r(sys: 128, dia: 82, pulse: 70);
    final id = await svc.writeReading(reading);

    expect(id, isNotNull);
    // Blood pressure: a single combined write, not two separate data points.
    expect(fake.bpWrites.length, 1);
    expect(fake.bpWrites.single.systolic, 128);
    expect(fake.bpWrites.single.diastolic, 82);
    expect(fake.bpWrites.single.startTime, reading.reading.measuredAt);
    // Stable client-record id makes the BP write an idempotent upsert.
    expect(fake.bpWrites.single.clientRecordId, 'pulsesnap-bp-1');
    // Heart rate: one writeHealthData call.
    expect(fake.writes.length, 1);
    expect(fake.writes.single.type, HealthDataType.HEART_RATE);
    expect(fake.writes.single.value, 70);
    expect(fake.writes.single.startTime, reading.reading.measuredAt);
    expect(fake.writes.single.clientRecordId, 'pulsesnap-hr-1');
  });

  test('null pulse skips HR write', () async {
    final fake = _FakeHealthFacade();
    final svc = HealthPlusService(facade: fake);
    final id = await svc.writeReading(_r(pulse: null));

    expect(id, isNotNull);
    expect(fake.writes, isEmpty);
    expect(fake.bpWrites.length, 1);
  });

  test('missing systolic skips BP write', () async {
    final fake = _FakeHealthFacade();
    final svc = HealthPlusService(facade: fake);
    await svc.writeReading(_r(sys: null, dia: 82, pulse: 70));

    expect(fake.bpWrites, isEmpty);
    expect(fake.writes.length, 1);
    expect(fake.writes.single.type, HealthDataType.HEART_RATE);
  });

  test('partial write failure returns null so it is not marked synced',
      () async {
    final fake = _FakeHealthFacade()..hrWriteOk = false;
    final svc = HealthPlusService(facade: fake);

    // BP write succeeds, HR write fails -> reading is not fully synced.
    final id = await svc.writeReading(_r(sys: 128, dia: 82, pulse: 70));

    expect(id, isNull);
    expect(fake.bpWrites.length, 1);
    expect(fake.writes.length, 1);
  });
}
