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
  Future<void> revokePermissions() async {}
}

class _Write {
  final HealthDataType type;
  final double value;
  final DateTime startTime;
  _Write(this.type, this.value, this.startTime);
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
  test('writeReading sends sys/dia/HR with measuredAt timestamp', () async {
    final fake = _FakeHealthFacade();
    final svc = HealthPlusService(facade: fake);
    final reading = _r(sys: 128, dia: 82, pulse: 70);
    final id = await svc.writeReading(reading);

    expect(id, isNotNull);
    expect(fake.writes.length, 3);
    final types = fake.writes.map((w) => w.type).toSet();
    expect(types, {
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.HEART_RATE,
    });
    for (final w in fake.writes) {
      expect(w.startTime, reading.reading.measuredAt);
    }
    final sysWrite = fake.writes
        .firstWhere((w) => w.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
    expect(sysWrite.value, 128);
  });

  test('null pulse skips HR write', () async {
    final fake = _FakeHealthFacade();
    final svc = HealthPlusService(facade: fake);
    final id = await svc.writeReading(_r(pulse: null));

    expect(id, isNotNull);
    expect(
      fake.writes.any((w) => w.type == HealthDataType.HEART_RATE),
      isFalse,
    );
    expect(fake.writes.length, 2);
  });

  test('missing systolic skips BP writes', () async {
    final fake = _FakeHealthFacade();
    final svc = HealthPlusService(facade: fake);
    await svc.writeReading(_r(sys: null, dia: 82, pulse: 70));

    expect(
      fake.writes.any((w) =>
          w.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC ||
          w.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC),
      isFalse,
    );
    expect(fake.writes.length, 1);
    expect(fake.writes.single.type, HealthDataType.HEART_RATE);
  });
}
