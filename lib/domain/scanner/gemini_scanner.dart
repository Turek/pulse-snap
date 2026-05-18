import 'dart:io';

import '../models/scan_result.dart';
import 'i_scanner.dart';

/// Phase 2: Gemini Flash via ASP.NET Core backend proxy.
class GeminiFlashScanner extends IScanner {
  final String backendUrl;
  GeminiFlashScanner({required this.backendUrl});

  @override
  ScannerType get type => ScannerType.geminiFlash;

  @override
  Future<ScanResult> scan(File imageFile) async {
    throw UnimplementedError('GeminiFlashScanner: Phase 2');
  }
}
