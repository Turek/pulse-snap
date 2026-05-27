import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/repositories/i_reading_repository.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';
import 'package:pulse_snap/features/review/review_screen.dart';
import 'package:pulse_snap/providers.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getTemporaryPath() async => tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

class _RecordingRepo implements IReadingRepository {
  List<String>? lastSavedTags;
  Reading? lastSavedReading;

  @override
  Future<void> saveReading(Reading reading,
      {List<String> tags = const []}) async {
    lastSavedReading = reading;
    lastSavedTags = List.of(tags);
  }

  @override
  Future<void> updateReading(Reading reading,
      {List<String> tags = const []}) async {}

  @override
  Future<void> deleteReading(int id) async {}

  @override
  Future<ReadingWithTags?> getReadingWithTags(int id) async => null;

  @override
  Stream<List<ReadingWithTags>> watchAllReadingsWithTags() =>
      const Stream.empty();

  @override
  Future<List<ReadingWithTags>> getReadingsByTag(String tag) async => const [];

  @override
  Future<List<String>> getAllUsedTags() async => const [];

  @override
  Future<int> backfillToHealthPlatform() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File image;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('review_tags_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    image = File('${tempDir.path}/sample.jpg');
    await image.writeAsBytes(List<int>.filled(8, 0));
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets(
      'selecting a default chip + adding a custom tag '
      'passes both to repository on save', (tester) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: ReviewForm.withInitial(
            imageFile: image,
            initial: const ScanResult(
              systolic: 120,
              diastolic: 80,
              pulse: 72,
              confidence: 0.9,
              source: ScannerType.mlKit,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap the "coffee" default chip.
    await tester.ensureVisible(find.text('coffee'));
    await tester.tap(find.text('coffee'));
    await tester.pump();

    // Open the custom input.
    await tester.ensureVisible(find.text('custom...'));
    await tester.tap(find.text('custom...'));
    await tester.pump();

    // Enter custom tag, tap Add.
    await tester.enterText(find.byType(TextField).last, 'headache + neck');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    // Save.
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(repo.lastSavedTags, isNotNull);
    expect(repo.lastSavedTags, contains('coffee'));
    expect(repo.lastSavedTags, contains('headache + neck'));
  });
}
