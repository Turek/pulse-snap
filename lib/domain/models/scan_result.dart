enum ScannerType { mlKit, tflite, geminiFlash, manual }

class ScanResult {
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final double confidence;
  final ScannerType source;
  final String? debugInfo;

  const ScanResult({
    this.systolic,
    this.diastolic,
    this.pulse,
    required this.confidence,
    required this.source,
    this.debugInfo,
  });

  bool get isComplete =>
      systolic != null && diastolic != null && pulse != null;

  bool get isPlausible =>
      (systolic ?? 0) >= 60 &&
      (systolic ?? 999) <= 250 &&
      (diastolic ?? 0) >= 40 &&
      (diastolic ?? 999) <= 150 &&
      (pulse ?? 0) >= 30 &&
      (pulse ?? 999) <= 220;

  ScanResult copyWith({
    int? systolic,
    int? diastolic,
    int? pulse,
    double? confidence,
    ScannerType? source,
    String? debugInfo,
  }) {
    return ScanResult(
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }
}
