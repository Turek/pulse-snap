import 'dart:io';

import '../models/scan_result.dart';

/// Diagnostic artifacts produced during a scan, surfaced on the review
/// screen so the user can see what the OCR engines actually got.
class ScanArtifacts {
  final ScanResult result;
  final File? cropImage;
  final File? binarizedImage;
  final List<int> candidateNumbers;
  final String? mlkitRawText;
  final String? tesseractRawText;
  final int? otsuThreshold;
  final bool? otsuInverted;

  const ScanArtifacts({
    required this.result,
    this.cropImage,
    this.binarizedImage,
    this.candidateNumbers = const [],
    this.mlkitRawText,
    this.tesseractRawText,
    this.otsuThreshold,
    this.otsuInverted,
  });
}
