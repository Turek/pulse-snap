/// Resting heart-rate classification per the addendum spec.
enum HeartRateStatus {
  veryLow,
  low,
  normal,
  mildlyHigh,
  high,
  veryHigh,
}

extension HeartRateStatusX on HeartRateStatus {
  String get label {
    switch (this) {
      case HeartRateStatus.veryLow:
        return 'Very Low';
      case HeartRateStatus.low:
        return 'Low';
      case HeartRateStatus.normal:
        return 'Normal';
      case HeartRateStatus.mildlyHigh:
        return 'Mildly High';
      case HeartRateStatus.high:
        return 'High';
      case HeartRateStatus.veryHigh:
        return 'Very High';
    }
  }
}
