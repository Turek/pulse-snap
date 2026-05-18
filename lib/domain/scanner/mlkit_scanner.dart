import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/scan_result.dart';
import 'i_scanner.dart';
import 'mlkit_logic.dart';
import 'preprocessing.dart';

class MlKitScanner extends IScanner {
  /// Injection seam: tests pass a fake recognizer.
  final Future<RecognizedText> Function(File preprocessed)? _recognize;

  /// Injection seam: tests skip preprocessing.
  final Future<File> Function(File source)? _preprocess;

  MlKitScanner({
    Future<RecognizedText> Function(File)? recognize,
    Future<File> Function(File)? preprocess,
  })  : _recognize = recognize,
        _preprocess = preprocess;

  @override
  ScannerType get type => ScannerType.mlKit;

  @override
  Future<ScanResult> scan(File imageFile) async {
    final preprocessed =
        await (_preprocess?.call(imageFile) ?? preprocessForOcr(imageFile));
    final recognized = await _runRecognizer(preprocessed);

    final numbers = <NumberBlock>[];
    final labels = <LabelBlock>[];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final raw = line.text.trim();
        final box = line.boundingBox;

        if (RegExp(r'^\d{2,3}$').hasMatch(raw)) {
          numbers.add(NumberBlock(
            value: int.parse(raw),
            box: box,
            confidence: line.confidence ?? 0.8,
          ));
        }
        final labelType = classifyLabel(raw);
        if (labelType != null) {
          labels.add(LabelBlock(type: labelType, box: box));
        }
      }
    }

    return combineProximityAndPosition(numbers, labels);
  }

  Future<RecognizedText> _runRecognizer(File preprocessed) async {
    if (_recognize != null) return _recognize(preprocessed);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFile(preprocessed);
      return await recognizer.processImage(input);
    } finally {
      await recognizer.close();
    }
  }
}
