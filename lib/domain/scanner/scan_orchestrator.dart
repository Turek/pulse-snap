import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/scan_result.dart';
import 'gemini_scanner.dart';
import 'i_scanner.dart';
import 'image_processing.dart';
import 'mlkit_scanner.dart';
import 'scan_artifacts.dart';
import 'tesseract_scanner.dart';

class ScanOrchestrator {
  final List<IScanner> _pipeline;

  ScanOrchestrator(this._pipeline);

  /// Legacy MVP pipeline (kept for tests / fallback if artifact pipeline
  /// errors out): Tesseract first, ML Kit second.
  factory ScanOrchestrator.mvp() =>
      ScanOrchestrator([TesseractScanner(), MlKitScanner()]);

  /// Runs scanners in order, returning the first confident & plausible result.
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

  /// High-fidelity pipeline used by the UI.
  ///
  /// If [geminiApiKey] is set, Gemini Flash is the primary scanner and
  /// returns a result immediately on success (vision LLM reads any 7-seg
  /// monitor reliably). On failure or when no key is configured, we fall
  /// back to the on-device pipeline:
  ///
  /// 1. ML Kit reads the whole image and locates chassis labels.
  /// 2. Crop to the inferred LCD region around those labels.
  /// 3. Otsu-binarize the crop (auto invert/no-invert).
  /// 4. Tesseract runs on the binarized image.
  /// 5. Filter candidates to BP-plausible ranges, assign in reading order.
  ///
  /// Returns [ScanArtifacts] with the result plus every diagnostic the
  /// review screen needs.
  static Future<ScanArtifacts> scanWithArtifacts(
    File imageFile, {
    String geminiApiKey = '',
  }) async {
    if (geminiApiKey.isNotEmpty) {
      final gemini = GeminiFlashScanner(apiKey: geminiApiKey);
      final geminiResult = await gemini.scan(imageFile);
      if (geminiResult.isComplete && geminiResult.isPlausible) {
        return ScanArtifacts(
          result: geminiResult,
          tesseractRawText: null,
          mlkitRawText: geminiResult.debugInfo,
        );
      }
      debugPrint(
        '[PulseSnap pipeline] Gemini did not produce a usable reading '
        '(confidence=${geminiResult.confidence}, '
        'isComplete=${geminiResult.isComplete}, '
        'isPlausible=${geminiResult.isPlausible}); falling back to on-device OCR',
      );
    }
    return _onDeviceWithArtifacts(imageFile);
  }

  static Future<ScanArtifacts> _onDeviceWithArtifacts(File imageFile) async {
    final mlkit = MlKitScanner();
    final tess = TesseractScanner();

    // Pass 1: ML Kit on full image — gives us labels + their boxes plus
    // any numbers it can read.
    final mlkitResult = await mlkit.scan(imageFile);

    // We also need ML Kit's label boxes; re-extract them from a quick
    // second call that returns the raw recognized data.
    final labelBoxes = await mlkit.extractLabelBoxes(imageFile);

    File ocrTarget = imageFile;
    File? cropImage;
    File? binarizedImage;
    int? threshold;
    bool? inverted;

    if (labelBoxes.isNotEmpty) {
      final union = unionOfBoxes(labelBoxes.map((b) => b.box));
      if (union != null) {
        try {
          final imageBytes = await imageFile.readAsBytes();
          // We need dimensions for clamping; reuse `image` package's
          // header read via cropAndBinarize which decodes anyway. Pass a
          // very large clamp here; cropAndBinarize clamps internally via
          // copyCrop on the decoded image.
          final expanded = expandLabelUnionToLcdRegion(
            union,
            // Decoder will clamp; using a permissive upper bound is fine
            // because expandLabelUnionToLcdRegion uses the dims we pass
            // only to clip its padding. Use 100k as "no upper limit".
            1 << 16,
            1 << 16,
          );
          final artifacts = await cropAndBinarize(
            imageFile,
            rect: expanded,
            prefix: 'pulsesnap_scan',
          );
          ocrTarget = artifacts.binaryFile;
          cropImage = artifacts.cropFile;
          binarizedImage = artifacts.binaryFile;
          threshold = artifacts.threshold;
          inverted = artifacts.inverted;
          debugPrint(
            '[PulseSnap pipeline] cropped to ${expanded.width}x${expanded.height} '
            'from label union; otsu=$threshold inverted=$inverted, bytes_in=${imageBytes.length}',
          );
        } catch (e) {
          debugPrint('[PulseSnap pipeline] crop/binarize failed: $e');
        }
      }
    } else {
      debugPrint(
        '[PulseSnap pipeline] no ML Kit labels detected; OCRing full image',
      );
    }

    // Run Tesseract on either the cropped binary or the original.
    final tessArtifacts =
        await tess.scanForCandidates(ocrTarget);

    // Combine: Tesseract candidates (numbers) + ML Kit labels (boxes).
    // For BP plausibility per slot.
    final assigned = _assignFromCandidates(tessArtifacts.candidates);

    // Pick whichever has more useful data — Tesseract assignment usually
    // wins on 7-seg, but if Tesseract found nothing the ML Kit result
    // (which may have caught numbers in some monitors) is still useful.
    final chosen = (assigned.isComplete && assigned.isPlausible)
        ? assigned
        : (mlkitResult.confidence > assigned.confidence
            ? mlkitResult
            : assigned);

    return ScanArtifacts(
      result: chosen.copyWith(
        debugInfo: 'tess: ${tessArtifacts.rawText}\nmlkit: ${mlkitResult.debugInfo}',
      ),
      cropImage: cropImage,
      binarizedImage: binarizedImage,
      candidateNumbers: tessArtifacts.candidates,
      tesseractRawText: tessArtifacts.rawText,
      mlkitRawText: mlkitResult.debugInfo,
      otsuThreshold: threshold,
      otsuInverted: inverted,
    );
  }

  void dispose() {
    for (final s in _pipeline) {
      s.dispose();
    }
  }
}

/// Heuristic assignment: take all plausible BP values from Tesseract, drop
/// duplicates/noise, then assign positionally — but only if we have at
/// least one number in each plausible range.
ScanResult _assignFromCandidates(List<int> candidates) {
  bool sysOk(int v) => v >= 80 && v <= 250;
  bool diaOk(int v) => v >= 40 && v <= 130;
  bool prOk(int v) => v >= 35 && v <= 200;

  // Tesseract candidates come in reading order. Walk through and pick
  // the first match for each slot.
  int? sys, dia, pr;
  for (final v in candidates) {
    if (sys == null && sysOk(v)) {
      sys = v;
      continue;
    }
    if (dia == null && diaOk(v) && (sys == null || v < sys)) {
      dia = v;
      continue;
    }
    if (pr == null && prOk(v)) {
      pr = v;
      continue;
    }
    if (sys != null && dia != null && pr != null) break;
  }

  final found = [sys, dia, pr].where((v) => v != null).length;
  return ScanResult(
    systolic: sys,
    diastolic: dia,
    pulse: pr,
    confidence: found == 3 ? 0.85 : found * 0.25,
    source: ScannerType.tesseract,
  );
}
