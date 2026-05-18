import 'dart:io';

import '../models/scan_result.dart';
import 'i_scanner.dart';
import 'mlkit_scanner.dart';

class ScanOrchestrator {
  final List<IScanner> _pipeline;

  ScanOrchestrator(this._pipeline);

  /// MVP pipeline: ML Kit only.
  factory ScanOrchestrator.mvp() => ScanOrchestrator([MlKitScanner()]);

  /// Runs scanners in order, returning the first confident & plausible result.
  /// If none qualify, returns the highest-confidence result seen.
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
