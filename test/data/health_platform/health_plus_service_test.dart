import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/health_platform/health_plus_service.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';

class _FakeHealthFacade extends HealthFacade {
  final List<_Write> writes = [];
  bool granted = true;

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
    DateTime? endTime,
    RecordingMethod recordingMethod = RecordingMethod.manual,
  }) async {
    writes.add(_Write(type, value, startTime));
    return true;
  }

  @override
  Future<bool> writeBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime startTime,
    RecordingMethod recordingMethod = RecordingMethod.manual,
  }) async {
    bpWrites.add(_BpWrite(systolic, diastolic, startTime));
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
  _Write(this.type, this.value, this.startTime);
}

class _BpWrite {
  final int systolic;
  final int diastolic;
  final DateTime startTime;
  _BpWrite(this.systolic, this.diastolic, this.startTime);
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
    // Heart rate: one writeHealthData call.
    expect(fake.writes.length, 1);
    expect(fake.writes.single.type, HealthDataType.HEART_RATE);
    expect(fake.writes.single.value, 70);
    expect(fake.writes.single.startTime, reading.reading.measuredAt);
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
}
