import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/scan_result.dart';
import 'i_scanner.dart';
import 'mlkit_logic.dart';

/// Reads 7-segment LCD digits using Tesseract with a community-trained
/// `letsgodigital` model. The package does not expose bounding boxes, so we
/// rely on Tesseract returning numbers in top-to-bottom reading order —
/// which matches BP monitor layouts (SYS on top, DIA below, pulse at bottom).
///
/// Pair this with [MlKitScanner] (for chassis labels) and feed the combined
/// result through [combineProximityAndPosition] — but for MVP the positional
/// heuristic alone works for the common case.
class TesseractScanner extends IScanner {
  static const _lang = 'letsgodigital';

  static Future<String>? _tessdataPath;

  @override
  ScannerType get type => ScannerType.tesseract;

  @override
  Future<ScanResult> scan(File imageFile) async {
    final String tessdata;
    try {
      tessdata = await _ensureTessdata();
    } catch (e) {
      debugPrint(
        '[PulseSnap Tesseract] traineddata missing — '
        'drop letsgodigital.traineddata into assets/tessdata/. Error: $e',
      );
      return const ScanResult(
        confidence: 0.0,
        source: ScannerType.tesseract,
        debugInfo: 'Tesseract traineddata missing; falling back to ML Kit',
      );
    }
    String text;
    try {
      text = await FlutterTesseractOcr.extractText(
        imageFile.path,
        language: _lang,
        args: {
          'tessdata': tessdata,
          'psm': '6', // assume a single uniform block of text
          'preserve_interword_spaces': '1',
        },
      );
    } catch (e) {
      debugPrint('[PulseSnap Tesseract] error: $e');
      return const ScanResult(
        confidence: 0.0,
        source: ScannerType.tesseract,
        debugInfo: 'Tesseract failed',
      );
    }

    final rawLines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final numbers = <NumberBlock>[];
    // Use a synthetic y coordinate per line so the positional fallback
    // (sort by box height) still works deterministically.
    for (var lineIdx = 0; lineIdx < rawLines.length; lineIdx++) {
      final line = rawLines[lineIdx];
      for (final m in RegExp(r'(?<!\d)(\d{2,3})(?!\d)').allMatches(line)) {
        numbers.add(NumberBlock(
          value: int.parse(m.group(1)!),
          // Height shrinks with line index so the first line wins as "largest".
          box: Rect.fromLTWH(0, lineIdx * 100.0, 60, 100 - lineIdx * 10.0),
          confidence: 0.85,
        ));
      }
    }

    debugPrint(
      '[PulseSnap Tesseract] numbers=${numbers.map((n) => n.value).toList()} '
      'raw="${rawLines.join(' | ')}"',
    );

    final result = assignByPosition(
      numbers,
      const ScanResult(confidence: 0.0, source: ScannerType.tesseract),
    );
    return result.copyWith(
      source: ScannerType.tesseract,
      debugInfo: 'tess: ${rawLines.join(' | ')}',
    );
  }

  /// Copies bundled traineddata files into the app's documents dir on first
  /// use. Tesseract reads them from disk.
  static Future<String> _ensureTessdata() {
    return _tessdataPath ??= _copyTessdataAssets();
  }

  static Future<String> _copyTessdataAssets() async {
    final docs = await getApplicationDocumentsDirectory();
    final tessdataDir = Directory(p.join(docs.path, 'tessdata'));
    if (!tessdataDir.existsSync()) {
      tessdataDir.createSync(recursive: true);
    }
    final target = File(p.join(tessdataDir.path, '$_lang.traineddata'));
    if (!target.existsSync()) {
      final data =
          await rootBundle.load('assets/tessdata/$_lang.traineddata');
      await target.writeAsBytes(data.buffer.asUint8List());
    }
    // flutter_tesseract_ocr expects the parent directory (containing
    // `tessdata/`), not `tessdata/` itself.
    return docs.path;
  }
}
