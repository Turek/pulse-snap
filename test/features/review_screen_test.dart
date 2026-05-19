import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/features/review/review_screen.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getTemporaryPath() async => tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

Widget _host(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File image;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('review_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    image = File('${tempDir.path}/sample.jpg');
    await image.writeAsBytes(List<int>.filled(8, 0));
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('shows low-confidence banner when initial < 0.75',
      (tester) async {
    await tester.pumpWidget(_host(ReviewForm.withInitial(
      imageFile: image,
      initial: const ScanResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        confidence: 0.6,
        source: ScannerType.mlKit,
      ),
    )));
    await tester.pump();
    expect(find.textContaining('Low confidence'), findsOneWidget);
  });

  testWidgets('save button disabled with implausible value', (tester) async {
    await tester.pumpWidget(_host(ReviewForm.withInitial(
      imageFile: image,
      initial: const ScanResult(
        systolic: 9,
        diastolic: 80,
        pulse: 72,
        confidence: 0.9,
        source: ScannerType.mlKit,
      ),
    )));
    await tester.pump();
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('save button enabled with plausible complete reading',
      (tester) async {
    await tester.pumpWidget(_host(ReviewForm.withInitial(
      imageFile: image,
      initial: const ScanResult(
        systolic: 110,
        diastolic: 70,
        pulse: 72,
        confidence: 0.9,
        source: ScannerType.mlKit,
      ),
    )));
    await tester.pump();
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(saveButton.onPressed, isNotNull);
    expect(find.text('Normal'), findsOneWidget);
  });
}
