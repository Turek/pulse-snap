# Tessdata setup

Place a 7-segment-trained Tesseract traineddata file at:

    assets/tessdata/letsgodigital.traineddata

Recommended source: <https://github.com/arturaugusto/display_ocr/tree/master/letsgodigital>
or any community-trained 7-seg model named `letsgodigital.traineddata`.

The file is not committed to git because it's an external trained model
(~1 MB). After adding it, run `flutter pub get` and rebuild.

If you want to skip the manual download and just use Latin-text OCR
without 7-seg support, drop in `eng.traineddata` instead and rename it
to `letsgodigital.traineddata` — extraction quality on 7-seg LCDs will
be poor.
