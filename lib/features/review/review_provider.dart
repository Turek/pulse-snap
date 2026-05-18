import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/scan_result.dart';
import '../../providers.dart';

final scanResultProvider =
    FutureProvider.family<ScanResult, File>((ref, file) async {
  final orch = ref.watch(scanOrchestratorProvider);
  return orch.process(file);
});
