import 'dart:typed_data';

import '../tags/reading_with_tags.dart';

/// Builds a doctor-facing PDF report over a date range. Implementations
/// must not include any personally identifying fields (name, address,
/// email).
abstract class IReportExportService {
  Future<Uint8List> buildPdfReport({
    required DateTime from,
    required DateTime to,
    required List<ReadingWithTags> readings,
  });
}
