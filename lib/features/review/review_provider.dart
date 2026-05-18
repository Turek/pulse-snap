import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scanner/scan_artifacts.dart';
import '../../domain/scanner/scan_orchestrator.dart';
import '../settings/settings_provider.dart';

final scanArtifactsProvider =
    FutureProvider.family<ScanArtifacts, File>((ref, file) async {
  // Await the stored key so the FIRST scan after launch doesn't race
  // with shared_preferences loading and silently fall through to the
  // (much worse) on-device pipeline with an empty key.
  final key = await ref.watch(geminiApiKeyProvider.future);
  return ScanOrchestrator.scanWithArtifacts(file, geminiApiKey: key);
});
