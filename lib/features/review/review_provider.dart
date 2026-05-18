import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scanner/scan_artifacts.dart';
import '../../domain/scanner/scan_orchestrator.dart';

final scanArtifactsProvider =
    FutureProvider.family<ScanArtifacts, File>((ref, file) async {
  return ScanOrchestrator.scanWithArtifacts(file);
});
