import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/scanner/i_scanner.dart';
import 'package:pulse_snap/domain/scanner/scan_orchestrator.dart';

class _FakeScanner extends IScanner {
  final ScannerType _type;
  final ScanResult _result;
  int callCount = 0;
  _FakeScanner(this._type, this._result);

  @override
  ScannerType get type => _type;

  @override
  Future<ScanResult> scan(File imageFile) async {
    callCount++;
    return _result;
  }

  @override
  void dispose() {}
}

void main() {
  final fakeFile = File('/dev/null');

  test('returns first confident & plausible result, short-circuits pipeline',
      () async {
    final s1 = _FakeScanner(
      ScannerType.tflite,
      const ScanResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        confidence: 0.9,
        source: ScannerType.tflite,
      ),
    );
    final s2 = _FakeScanner(
      ScannerType.mlKit,
      const ScanResult(
        confidence: 1.0,
        source: ScannerType.mlKit,
      ),
    );
    final orch = ScanOrchestrator([s1, s2]);
    final r = await orch.process(fakeFile);
    expect(r.source, ScannerType.tflite);
    expect(s2.callCount, 0);
  });

  test('skips low-confidence result and tries next scanner', () async {
    final s1 = _FakeScanner(
      ScannerType.mlKit,
      const ScanResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        confidence: 0.4,
        source: ScannerType.mlKit,
      ),
    );
    final s2 = _FakeScanner(
      ScannerType.geminiFlash,
      const ScanResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        confidence: 0.95,
        source: ScannerType.geminiFlash,
      ),
    );
    final orch = ScanOrchestrator([s1, s2]);
    final r = await orch.process(fakeFile);
    expect(r.source, ScannerType.geminiFlash);
    expect(s1.callCount, 1);
    expect(s2.callCount, 1);
  });

  test('skips implausible result even if confidence is high', () async {
    final s1 = _FakeScanner(
      ScannerType.mlKit,
      const ScanResult(
        systolic: 9,
        diastolic: 80,
        pulse: 72,
        confidence: 0.99,
        source: ScannerType.mlKit,
      ),
    );
    final s2 = _FakeScanner(
      ScannerType.geminiFlash,
      const ScanResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        confidence: 0.8,
        source: ScannerType.geminiFlash,
      ),
    );
    final orch = ScanOrchestrator([s1, s2]);
    final r = await orch.process(fakeFile);
    expect(r.source, ScannerType.geminiFlash);
  });

  test('returns best-of when nothing meets threshold', () async {
    final s1 = _FakeScanner(
      ScannerType.mlKit,
      const ScanResult(confidence: 0.3, source: ScannerType.mlKit),
    );
    final s2 = _FakeScanner(
      ScannerType.geminiFlash,
      const ScanResult(confidence: 0.5, source: ScannerType.geminiFlash),
    );
    final orch = ScanOrchestrator([s1, s2]);
    final r = await orch.process(fakeFile);
    expect(r.source, ScannerType.geminiFlash);
    expect(r.confidence, 0.5);
  });
}
