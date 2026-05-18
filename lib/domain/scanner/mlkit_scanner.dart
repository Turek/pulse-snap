import 'dart:io';

import 'package:flutter/foundation.dart';
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
    // First pass: lightly preprocessed image.
    final preprocessed =
        await (_preprocess?.call(imageFile) ?? preprocessForOcr(imageFile));
    var pass = await _extractFromFile(preprocessed, passLabel: 'preprocessed');

    // Fallback: if the preprocessed pass produced no numbers at all, try
    // the raw image. Preprocessing helps sometimes, hurts other times — let
    // both vote.
    if (pass.numbers.isEmpty) {
      final raw = await _extractFromFile(imageFile, passLabel: 'raw');
      if (raw.numbers.isNotEmpty) pass = raw;
    }

    final result = combineProximityAndPosition(pass.numbers, pass.labels);
    return result.copyWith(
      debugInfo: pass.rawLines.where((l) => l.isNotEmpty).join(' | '),
    );
  }

  Future<_ExtractedBlocks> _extractFromFile(
    File file, {
    required String passLabel,
  }) async {
    final recognized = await _runRecognizer(file);
    final numbers = <NumberBlock>[];
    final labels = <LabelBlock>[];
    final rawLines = <String>[];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final raw = line.text.trim();
        rawLines.add(raw);
        final box = line.boundingBox;
        final conf = line.confidence ?? 0.8;

        for (final m in RegExp(r'(?<!\d)(\d{2,3})(?!\d)').allMatches(raw)) {
          numbers.add(NumberBlock(
            value: int.parse(m.group(1)!),
            box: box,
            confidence: conf,
          ));
        }

        final labelType = classifyLabel(raw);
        if (labelType != null) {
          labels.add(LabelBlock(type: labelType, box: box));
        }
      }
    }

    debugPrint(
      '[PulseSnap OCR pass=$passLabel] lines=${rawLines.length} '
      'numbers=${numbers.map((n) => n.value).toList()} '
      'labels=${labels.map((l) => l.type.name).toList()}\n'
      'raw="${rawLines.join(' | ')}"',
    );

    return _ExtractedBlocks(numbers: numbers, labels: labels, rawLines: rawLines);
  }

  Future<RecognizedText> _runRecognizer(File file) async {
    if (_recognize != null) return _recognize(file);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFile(file);
      return await recognizer.processImage(input);
    } finally {
      await recognizer.close();
    }
  }
}

class _ExtractedBlocks {
  final List<NumberBlock> numbers;
  final List<LabelBlock> labels;
  final List<String> rawLines;
  _ExtractedBlocks({
    required this.numbers,
    required this.labels,
    required this.rawLines,
  });
}
