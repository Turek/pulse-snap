import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Rectangular crop in pixel coordinates of the source image.
class CropRect {
  final int left, top, width, height;
  const CropRect(this.left, this.top, this.width, this.height);
  int get right => left + width;
  int get bottom => top + height;
}

/// Expand a tight rectangle (e.g. union of chassis-label boxes) to also
/// cover the larger LCD digits sitting above/around the labels.
/// BP monitor layouts: labels are small text near each digit row.
CropRect expandLabelUnionToLcdRegion(
  CropRect labels,
  int imageWidth,
  int imageHeight,
) {
  // Digits are typically 3-5× the height of their labels. Expand mostly
  // upward and a bit downward, with generous horizontal padding.
  final padX = (labels.width * 0.4).round();
  final padTop = (labels.height * 3.5).round();
  final padBottom = (labels.height * 1.2).round();

  final left = math.max(0, labels.left - padX);
  final top = math.max(0, labels.top - padTop);
  final right = math.min(imageWidth, labels.right + padX);
  final bottom = math.min(imageHeight, labels.bottom + padBottom);
  return CropRect(left, top, right - left, bottom - top);
}

/// Otsu's method: pick the threshold that maximises between-class variance.
int otsuThreshold(img.Image grayscale) {
  final hist = List<int>.filled(256, 0);
  for (final pixel in grayscale) {
    hist[pixel.r.toInt().clamp(0, 255)]++;
  }
  final total = grayscale.width * grayscale.height;
  double sumTotal = 0;
  for (var i = 0; i < 256; i++) {
    sumTotal += i * hist[i];
  }
  var sumB = 0.0;
  var wB = 0;
  var maxVar = 0.0;
  var threshold = 127;
  for (var i = 0; i < 256; i++) {
    wB += hist[i];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += i * hist[i];
    final mB = sumB / wB;
    final mF = (sumTotal - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > maxVar) {
      maxVar = between;
      threshold = i;
    }
  }
  return threshold;
}

/// Binarize a grayscale image at [threshold]. If [invert] is true, pixels
/// brighter than the threshold become black (used when digits are the dark
/// shapes on a light background — typical for most LCDs).
img.Image binarize(img.Image gray, int threshold, {required bool invert}) {
  final out = img.Image.from(gray);
  for (final pixel in out) {
    final isAbove = pixel.r >= threshold;
    final on = invert ? !isAbove : isAbove;
    final v = on ? 255 : 0;
    pixel.setRgb(v, v, v);
  }
  return out;
}

/// Auto-detect orientation: if the mean pixel is dark, the image is
/// "bright on dark" and we should NOT invert; if mean is bright, digits are
/// dark on light and we SHOULD invert so Tesseract sees dark-on-light
/// (its expectation).
bool shouldInvertForOcr(img.Image gray) {
  var sum = 0;
  var count = 0;
  for (final pixel in gray) {
    sum += pixel.r.toInt();
    count++;
  }
  final mean = sum / count;
  // If image is mostly bright (mean >127), digits are dark — leave as-is.
  // If image is mostly dark, digits are bright — invert.
  return mean < 127;
}

/// Crop [source] to [rect] and produce two on-disk files:
///
/// - `<prefix>_crop.jpg`   — grayscale crop, light contrast bump
/// - `<prefix>_binary.png` — Otsu-binarized version for OCR
///
/// Returns paths to both, and the threshold used (for diagnostics).
class CropArtifacts {
  final File cropFile;
  final File binaryFile;
  final int threshold;
  final bool inverted;
  const CropArtifacts({
    required this.cropFile,
    required this.binaryFile,
    required this.threshold,
    required this.inverted,
  });
}

Future<CropArtifacts> cropAndBinarize(
  File source, {
  required CropRect rect,
  required String prefix,
}) async {
  final bytes = await source.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Cannot decode source image');
  }
  final cropped = img.copyCrop(
    decoded,
    x: rect.left,
    y: rect.top,
    width: rect.width,
    height: rect.height,
  );
  var gray = img.grayscale(cropped);
  gray = img.adjustColor(gray, contrast: 1.2);

  final invert = shouldInvertForOcr(gray);
  final threshold = otsuThreshold(gray);
  final binary = binarize(gray, threshold, invert: invert);

  final dir = await getTemporaryDirectory();
  final tag = DateTime.now().microsecondsSinceEpoch;
  final cropPath = p.join(dir.path, '${prefix}_${tag}_crop.jpg');
  final binPath = p.join(dir.path, '${prefix}_${tag}_binary.png');
  await File(cropPath).writeAsBytes(img.encodeJpg(gray, quality: 92));
  await File(binPath).writeAsBytes(img.encodePng(binary));

  return CropArtifacts(
    cropFile: File(cropPath),
    binaryFile: File(binPath),
    threshold: threshold,
    inverted: invert,
  );
}

/// Wraps a list of [Rect]-like boxes into a single union [CropRect].
/// Returns null if [boxes] is empty.
CropRect? unionOfBoxes(Iterable<Rect> boxes) {
  num? l, t, r, b;
  for (final box in boxes) {
    l = l == null ? box.left : math.min(l, box.left);
    t = t == null ? box.top : math.min(t, box.top);
    r = r == null ? box.right : math.max(r, box.right);
    b = b == null ? box.bottom : math.max(b, box.bottom);
  }
  if (l == null) return null;
  return CropRect(l.round(), t!.round(), (r! - l).round(), (b! - t).round());
}

