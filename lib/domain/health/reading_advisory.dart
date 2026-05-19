import 'blood_pressure_status.dart';
import 'heart_rate_status.dart';

/// Combined advisory copy for a reading — single source of truth shared
/// by Review and Detail screens.
class ReadingAdvisory {
  /// Banner message shown above the reading (e.g. for hypertensive crisis).
  final String? bannerMessage;

  /// Subtitle override for the blood-pressure pill (e.g. low BP guidance).
  final String? bpSubtitle;

  /// Subtitle override for the heart-rate pill (e.g. elevated pulse context).
  final String? hrSubtitle;

  const ReadingAdvisory({
    this.bannerMessage,
    this.bpSubtitle,
    this.hrSubtitle,
  });
}

/// Computes contextual copy from status enums + the reading's tag set.
ReadingAdvisory computeAdvisory({
  required BloodPressureStatus? bp,
  required HeartRateStatus? hr,
  required Set<String> tags,
}) {
  final lower = tags.map((t) => t.toLowerCase()).toSet();
  final hasSymptom = lower.contains('dizziness') || lower.contains('headache');
  final afterExercise = lower.contains('after exercise');

  String? banner;
  if (bp == BloodPressureStatus.crisis) {
    banner = 'Very high reading — consider seeking medical advice.';
  }

  String? bpSub;
  if (bp == BloodPressureStatus.low) {
    bpSub = hasSymptom
        ? 'Low blood pressure with symptoms — consider seeking medical advice.'
        : 'Below the typical range — usually not concerning without symptoms.';
  }

  String? hrSub;
  if (hr == HeartRateStatus.mildlyHigh ||
      hr == HeartRateStatus.high ||
      hr == HeartRateStatus.veryHigh) {
    hrSub = afterExercise
        ? 'Elevated pulse may reflect recent activity.'
        : 'Resting pulse is above the normal range.';
  }

  return ReadingAdvisory(
    bannerMessage: banner,
    bpSubtitle: bpSub,
    hrSubtitle: hrSub,
  );
}
