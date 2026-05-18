import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scanner/scan_artifacts.dart';
import '../../domain/scanner/scan_orchestrator.dart';

import '../settings/settings_provider.dart';

final scanArtifactsProvider =
    FutureProvider.family<ScanArtifacts, File>((ref, file) async {
  final keyAsync = ref.watch(geminiApiKeyProvider);
  final key = keyAsync.maybeWhen(data: (k) => k, orElse: () => '');
  return ScanOrchestrator.scanWithArtifacts(file, geminiApiKey: key);
});
