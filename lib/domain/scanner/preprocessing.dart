import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Minimal preprocessing for ML Kit: ML Kit's text recognizer is robust on
/// raw colour images, and aggressive sharpen/contrast filters tend to corrupt
/// 7-segment LCD digits. We only downscale very large images (memory) and
/// boost contrast slightly. Grayscale conversion and sharpen convolutions
/// were removed because they hurt accuracy in real-world testing.
Future<File> preprocessForOcr(File source) async {
  final bytes = await source.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('Cannot decode image for OCR preprocessing');
  }

  // Downscale very large captures so ML Kit isn't memory-bottlenecked.
  const maxDim = 2000;
  if (image.width > maxDim || image.height > maxDim) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? maxDim : null,
      height: image.height > image.width ? maxDim : null,
      interpolation: img.Interpolation.linear,
    );
  }

  // Gentle contrast bump only.
  image = img.adjustColor(image, contrast: 1.15);

  final dir = await getTemporaryDirectory();
  final outPath = p.join(
    dir.path,
    'pulsesnap_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  final out = File(outPath);
  await out.writeAsBytes(img.encodeJpg(image, quality: 95));
  return out;
}
