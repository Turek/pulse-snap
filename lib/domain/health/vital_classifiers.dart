import 'blood_pressure_status.dart';
import 'heart_rate_status.dart';
import 'severity_level.dart';

BloodPressureStatus classifyBloodPressure({
  required int systolic,
  required int diastolic,
}) {
  if (systolic > 180 || diastolic > 120) {
    return BloodPressureStatus.crisis;
  }
  if (systolic >= 140 || diastolic >= 90) {
    return BloodPressureStatus.highStage2;
  }
  if ((systolic >= 130 && systolic <= 139) ||
      (diastolic >= 80 && diastolic <= 89)) {
    return BloodPressureStatus.highStage1;
  }
  if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
    return BloodPressureStatus.elevated;
  }
  if (systolic < 90 || diastolic < 60) {
    return BloodPressureStatus.low;
  }
  return BloodPressureStatus.normal;
}

HeartRateStatus classifyHeartRate({
  required int bpm,
}) {
  if (bpm > 130) return HeartRateStatus.veryHigh;
  if (bpm >= 111) return HeartRateStatus.high;
  if (bpm >= 101) return HeartRateStatus.mildlyHigh;
  if (bpm >= 60) return HeartRateStatus.normal;
  if (bpm >= 50) return HeartRateStatus.low;
  return HeartRateStatus.veryLow;
}

SeverityLevel severityFromBloodPressure(BloodPressureStatus status) {
  switch (status) {
    case BloodPressureStatus.low:
      return SeverityLevel.info;
    case BloodPressureStatus.normal:
      return SeverityLevel.normal;
    case BloodPressureStatus.elevated:
      return SeverityLevel.caution;
    case BloodPressureStatus.highStage1:
      return SeverityLevel.warning;
    case BloodPressureStatus.highStage2:
      return SeverityLevel.danger;
    case BloodPressureStatus.crisis:
      return SeverityLevel.urgent;
  }
}

SeverityLevel severityFromHeartRate(HeartRateStatus status) {
  switch (status) {
    case HeartRateStatus.veryLow:
      return SeverityLevel.info;
    case HeartRateStatus.low:
      return SeverityLevel.caution;
    case HeartRateStatus.normal:
      return SeverityLevel.normal;
    case HeartRateStatus.mildlyHigh:
      return SeverityLevel.caution;
    case HeartRateStatus.high:
      return SeverityLevel.warning;
    case HeartRateStatus.veryHigh:
      return SeverityLevel.danger;
  }
}
