import 'dart:io';

import '../models/scan_result.dart';
import 'i_scanner.dart';

/// Phase 2: TFLite MobileNet-SSD detects SYS/DIA/PULSE bounding boxes,
/// then each crop is fed to MlKitScanner.
class TfLiteRegionScanner extends IScanner {
  @override
  ScannerType get type => ScannerType.tflite;

  @override
  Future<ScanResult> scan(File imageFile) async {
    throw UnimplementedError('TfLiteRegionScanner: Phase 2');
  }
}
