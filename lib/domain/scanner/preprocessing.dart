import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sharpens, boosts contrast, and converts to grayscale to improve OCR
/// accuracy on 7-segment LCD displays.
Future<File> preprocessForOcr(File source) async {
  final bytes = await source.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('Cannot decode image for OCR preprocessing');
  }

  image = img.grayscale(image);
  image = img.adjustColor(image, contrast: 1.5, brightness: 1.1);
  image = img.convolution(
    image,
    filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ],
    div: 1,
  );

  final dir = await getTemporaryDirectory();
  final outPath = p.join(
    dir.path,
    'pulsesnap_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  final out = File(outPath);
  await out.writeAsBytes(img.encodeJpg(image, quality: 95));
  return out;
}
