import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/data/export/pdf_report_service.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';

ReadingWithTags _r({
  required DateTime at,
  int sys = 124,
  int dia = 82,
  int pulse = 70,
  ScannerType source = ScannerType.mlKit,
  List<String> tags = const [],
}) =>
    ReadingWithTags(
      reading: Reading(
        id: 0,
        userId: 'default',
        measuredAt: at,
        systolic: sys,
        diastolic: dia,
        pulse: pulse,
        sourceType: source,
        ocrConfidence: 0.9,
        isManuallyEdited: false,
        createdAt: at,
      ),
      tags: tags,
    );

void main() {
  // Disable stream compression so the test can string-search the bytes.
  final service = PdfReportService(compress: false);

  test('builds a non-empty PDF containing required content', () async {
    final to = DateTime(2026, 5, 19, 9);
    final from = to.subtract(const Duration(days: 7));
    final readings = [
      _r(at: from.add(const Duration(days: 1, hours: 8)), sys: 122, dia: 78, pulse: 68, tags: ['sitting']),
      _r(at: from.add(const Duration(days: 2, hours: 19)), sys: 134, dia: 86, pulse: 76),
      _r(at: from.add(const Duration(days: 4, hours: 7)), sys: 118, dia: 76, pulse: 64, source: ScannerType.manual, tags: ['after coffee']),
      _r(at: from.add(const Duration(days: 5, hours: 20)), sys: 142, dia: 92, pulse: 80),
      _r(at: from.add(const Duration(days: 6, hours: 8)), sys: 128, dia: 82, pulse: 70, tags: ['stress']),
    ];

    final bytes = await service.buildPdfReport(
      from: from,
      to: to,
      readings: readings,
    );

    expect(bytes.isNotEmpty, isTrue);

    final text = utf8.decode(bytes, allowMalformed: true);

    // The `pdf` package emits each word as a separate `(word) TJ` op, so
    // multi-word phrases won't appear as contiguous substrings. Match
    // word-by-word instead.
    void expectAllWords(String phrase) {
      for (final w in phrase.split(RegExp(r'\s+'))) {
        if (w.isEmpty) continue;
        expect(text, contains('($w)'),
            reason: 'expected PDF to contain word "$w" from "$phrase"');
      }
    }

    // Title & summary labels.
    expectAllWords('PulseSnap Blood Pressure');
    expectAllWords('Average systolic');
    expectAllWords('Average diastolic');
    expectAllWords('Average pulse');
    expectAllWords('Highest BP');
    expectAllWords('Lowest BP');

    // Detail table headers — single tokens.
    expect(text, contains('(SYS)'));
    expect(text, contains('(DIA)'));
    expect(text, contains('(Pulse)'));
    expect(text, contains('(Tags)'));
    expect(text, contains('(Source)'));
    expectAllWords('BP Status');
    expectAllWords('HR Status');

    // Verbatim footer (word by word, in document order).
    expectAllWords(
      'This report contains home-monitored readings recorded in PulseSnap. '
      'It is intended to support review and discussion with a clinician and is not a diagnosis.',
    );

    // Negative: no PII labels.
    expect(text, isNot(contains('Name:')));
    expect(text, isNot(contains('Email:')));
    expect(text, isNot(contains('Address:')));
    expect(text, isNot(contains('Patient:')));
  });

  test('empty readings list still builds a non-empty PDF', () async {
    final to = DateTime(2026, 5, 19);
    final from = to.subtract(const Duration(days: 7));
    final bytes = await service.buildPdfReport(
      from: from,
      to: to,
      readings: const [],
    );
    expect(bytes.isNotEmpty, isTrue);
  });
}
