import 'dart:io';

import '../models/scan_result.dart';

abstract class IScanner {
  ScannerType get type;

  /// Process a captured image and return extracted vital signs.
  Future<ScanResult> scan(File imageFile);

  /// Release any underlying resources (model instances, recognizers).
  void dispose() {}
}
