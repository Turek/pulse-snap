import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';
import 'package:pulse_snap/features/export/export_provider.dart';
import 'package:pulse_snap/features/export/export_screen.dart';
import 'package:pulse_snap/providers.dart';

ReadingWithTags _r(DateTime at, {int sys = 120}) => ReadingWithTags(
      reading: Reading(
        id: at.millisecondsSinceEpoch ~/ 1000,
        userId: 'default',
        measuredAt: at,
        systolic: sys,
        diastolic: 80,
        pulse: 72,
        sourceType: ScannerType.mlKit,
        isManuallyEdited: false,
        createdAt: at,
      ),
      tags: const [],
    );

void main() {
  testWidgets('Last 14 days segment updates the displayed range',
      (tester) async {
    final now = DateTime.now();
    final readings = [
      _r(now.subtract(const Duration(days: 1))),
      _r(now.subtract(const Duration(days: 10))),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsProvider.overrideWith((ref) => Stream.value(readings)),
        ],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Initially "7 days" selected.
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ExportScreen)));
    expect(container.read(exportOptionsProvider).preset,
        ExportRangePreset.last7Days);

    // Tap the 14 days preset.
    await tester.tap(find.text('Last 14 days'));
    await tester.pumpAndSettle();

    final updated = container.read(exportOptionsProvider);
    expect(updated.preset, ExportRangePreset.last14Days);
    final spanDays = updated.to.difference(updated.from).inDays;
    expect(spanDays, inInclusiveRange(13, 14));
  });

  testWidgets('Generate preview button is enabled with data',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsProvider.overrideWith(
              (ref) => Stream<List<ReadingWithTags>>.value(const [])),
        ],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final btn = find.widgetWithText(FilledButton, 'Generate preview');
    expect(btn, findsOneWidget);
    final button = tester.widget<FilledButton>(btn);
    expect(button.onPressed, isNotNull);
  });

  test('filterReadings narrows by range and source', () {
    final base = DateTime(2026, 5, 10, 12);
    final all = [
      ReadingWithTags(
        reading: Reading(
          id: 1,
          userId: 'default',
          measuredAt: base,
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          sourceType: ScannerType.mlKit,
          isManuallyEdited: false,
          createdAt: base,
        ),
        tags: const [],
      ),
      ReadingWithTags(
        reading: Reading(
          id: 2,
          userId: 'default',
          measuredAt: base.add(const Duration(days: 2)),
          systolic: 118,
          diastolic: 78,
          pulse: 68,
          sourceType: ScannerType.manual,
          isManuallyEdited: false,
          createdAt: base,
        ),
        tags: const [],
      ),
      ReadingWithTags(
        reading: Reading(
          id: 3,
          userId: 'default',
          measuredAt: base.subtract(const Duration(days: 10)),
          systolic: 116,
          diastolic: 76,
          pulse: 64,
          sourceType: ScannerType.mlKit,
          isManuallyEdited: false,
          createdAt: base,
        ),
        tags: const [],
      ),
    ];

    final opts = ExportOptions(
      preset: ExportRangePreset.custom,
      from: base.subtract(const Duration(days: 1)),
      to: base.add(const Duration(days: 3)),
      includeScanned: true,
      includeManual: false,
    );
    final filtered = filterReadings(all, opts);
    expect(filtered.map((r) => r.reading.id), [1]);
  });
}
