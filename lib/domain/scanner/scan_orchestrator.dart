import 'dart:io';

import '../models/scan_result.dart';
import 'i_scanner.dart';
import 'mlkit_scanner.dart';
import 'tesseract_scanner.dart';

class ScanOrchestrator {
  final List<IScanner> _pipeline;

  ScanOrchestrator(this._pipeline);

  /// MVP pipeline: Tesseract first (7-seg digits), ML Kit second (chassis
  /// labels / fallback). The orchestrator returns the first confident +
  /// plausible result; if Tesseract reads numbers correctly we stop there.
  factory ScanOrchestrator.mvp() =>
      ScanOrchestrator([TesseractScanner(), MlKitScanner()]);

  /// Runs scanners in order, returning the first confident & plausible result.
  /// If none qualify, returns the highest-confidence result seen.
  /// Even a partial result is returned so the UI can pre-fill what was found
  /// and let the user finish typing the rest — better than blocking on
  /// "perfect" extraction.
  Future<ScanResult> process(File imageFile) async {
    ScanResult? best;
    for (final scanner in _pipeline) {
      final result = await scanner.scan(imageFile);
      if (result.isComplete &&
          result.isPlausible &&
          result.confidence >= 0.75) {
        return result;
      }
      if (best == null || result.confidence > best.confidence) {
        best = result;
      }
    }
    return best!;
  }

  void dispose() {
    for (final s in _pipeline) {
      s.dispose();
    }
  }
}
