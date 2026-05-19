import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/domain/health/blood_pressure_status.dart';
import 'package:pulse_snap/domain/health/heart_rate_status.dart';
import 'package:pulse_snap/domain/health/severity_level.dart';
import 'package:pulse_snap/domain/health/vital_classifiers.dart';

void main() {
  group('classifyBloodPressure', () {
    test('128/92 → highStage2 (diastolic forces stage 2)', () {
      expect(
        classifyBloodPressure(systolic: 128, diastolic: 92),
        BloodPressureStatus.highStage2,
      );
    });

    test('135/85 → highStage1', () {
      expect(
        classifyBloodPressure(systolic: 135, diastolic: 85),
        BloodPressureStatus.highStage1,
      );
    });

    test('125/79 → elevated', () {
      expect(
        classifyBloodPressure(systolic: 125, diastolic: 79),
        BloodPressureStatus.elevated,
      );
    });

    test('119/79 → normal', () {
      expect(
        classifyBloodPressure(systolic: 119, diastolic: 79),
        BloodPressureStatus.normal,
      );
    });

    test('89/59 → low', () {
      expect(
        classifyBloodPressure(systolic: 89, diastolic: 59),
        BloodPressureStatus.low,
      );
    });

    test('181/121 → crisis', () {
      expect(
        classifyBloodPressure(systolic: 181, diastolic: 121),
        BloodPressureStatus.crisis,
      );
    });

    test('200/85 → crisis (systolic > 180 alone)', () {
      expect(
        classifyBloodPressure(systolic: 200, diastolic: 85),
        BloodPressureStatus.crisis,
      );
    });

    test('140/89 → highStage2 (systolic ≥ 140)', () {
      expect(
        classifyBloodPressure(systolic: 140, diastolic: 89),
        BloodPressureStatus.highStage2,
      );
    });
  });

  group('classifyHeartRate', () {
    test('boundary and representative values', () {
      expect(classifyHeartRate(bpm: 49), HeartRateStatus.veryLow);
      expect(classifyHeartRate(bpm: 55), HeartRateStatus.low);
      expect(classifyHeartRate(bpm: 70), HeartRateStatus.normal);
      expect(classifyHeartRate(bpm: 105), HeartRateStatus.mildlyHigh);
      expect(classifyHeartRate(bpm: 120), HeartRateStatus.high);
      expect(classifyHeartRate(bpm: 131), HeartRateStatus.veryHigh);
      expect(classifyHeartRate(bpm: 60), HeartRateStatus.normal);
      expect(classifyHeartRate(bpm: 100), HeartRateStatus.normal);
      expect(classifyHeartRate(bpm: 101), HeartRateStatus.mildlyHigh);
      expect(classifyHeartRate(bpm: 111), HeartRateStatus.high);
    });
  });

  group('severityFromBloodPressure', () {
    test('maps every enum value to expected severity', () {
      expect(severityFromBloodPressure(BloodPressureStatus.low),
          SeverityLevel.info);
      expect(severityFromBloodPressure(BloodPressureStatus.normal),
          SeverityLevel.normal);
      expect(severityFromBloodPressure(BloodPressureStatus.elevated),
          SeverityLevel.caution);
      expect(severityFromBloodPressure(BloodPressureStatus.highStage1),
          SeverityLevel.warning);
      expect(severityFromBloodPressure(BloodPressureStatus.highStage2),
          SeverityLevel.danger);
      expect(severityFromBloodPressure(BloodPressureStatus.crisis),
          SeverityLevel.urgent);
    });
  });

  group('severityFromHeartRate', () {
    test('maps every enum value to expected severity', () {
      expect(severityFromHeartRate(HeartRateStatus.veryLow),
          SeverityLevel.info);
      expect(severityFromHeartRate(HeartRateStatus.low),
          SeverityLevel.caution);
      expect(severityFromHeartRate(HeartRateStatus.normal),
          SeverityLevel.normal);
      expect(severityFromHeartRate(HeartRateStatus.mildlyHigh),
          SeverityLevel.caution);
      expect(severityFromHeartRate(HeartRateStatus.high),
          SeverityLevel.warning);
      expect(severityFromHeartRate(HeartRateStatus.veryHigh),
          SeverityLevel.danger);
    });
  });
}
