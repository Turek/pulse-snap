/// Blood pressure classification per the addendum spec.
///
/// Thresholds follow AHA categories plus an NHS-aligned `low` bucket.
enum BloodPressureStatus {
  low,
  normal,
  elevated,
  highStage1,
  highStage2,
  crisis,
}

extension BloodPressureStatusX on BloodPressureStatus {
  String get label {
    switch (this) {
      case BloodPressureStatus.low:
        return 'Low';
      case BloodPressureStatus.normal:
        return 'Normal';
      case BloodPressureStatus.elevated:
        return 'Elevated';
      case BloodPressureStatus.highStage1:
        return 'High Stage 1';
      case BloodPressureStatus.highStage2:
        return 'High Stage 2';
      case BloodPressureStatus.crisis:
        return 'Crisis';
    }
  }
}
