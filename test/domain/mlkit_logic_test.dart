import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/domain/models/scan_result.dart';
import 'package:pulse_snap/domain/scanner/mlkit_logic.dart';

NumberBlock _n(int v, double x, double y, {double h = 40, double c = 0.9}) =>
    NumberBlock(
      value: v,
      box: Rect.fromLTWH(x, y, 60, h),
      confidence: c,
    );

LabelBlock _l(VitalType t, double x, double y) =>
    LabelBlock(type: t, box: Rect.fromLTWH(x, y, 60, 20));

void main() {
  group('classifyLabel', () {
    test('latin labels', () {
      expect(classifyLabel('SYS'), VitalType.systolic);
      expect(classifyLabel('mmHg'), VitalType.systolic);
      expect(classifyLabel('DIA'), VitalType.diastolic);
      expect(classifyLabel('Pulse'), VitalType.pulse);
      expect(classifyLabel('BPM'), VitalType.pulse);
    });
    test('CJK + multilingual pulse labels', () {
      expect(classifyLabel('脈拍'), VitalType.pulse);
      expect(classifyLabel('心率'), VitalType.pulse);
      expect(classifyLabel('Nadi'), VitalType.pulse);
    });
    test('unrelated text → null', () {
      expect(classifyLabel('user'), isNull);
      expect(classifyLabel(''), isNull);
    });
  });

  group('assignByProximity', () {
    test('all three labels present → high confidence assignment', () {
      final numbers = [
        _n(120, 100, 100),
        _n(80, 100, 200),
        _n(72, 100, 300),
      ];
      final labels = [
        _l(VitalType.systolic, 30, 100),
        _l(VitalType.diastolic, 30, 200),
        _l(VitalType.pulse, 30, 300),
      ];
      final r = assignByProximity(numbers, labels);
      expect(r.systolic, 120);
      expect(r.diastolic, 80);
      expect(r.pulse, 72);
      expect(r.confidence, greaterThanOrEqualTo(0.85));
      expect(r.isPlausible, true);
    });

    test('only 2 labels → lower confidence (2/3 multiplier)', () {
      final numbers = [_n(120, 100, 100), _n(80, 100, 200)];
      final labels = [
        _l(VitalType.systolic, 30, 100),
        _l(VitalType.diastolic, 30, 200),
      ];
      final r = assignByProximity(numbers, labels);
      expect(r.systolic, 120);
      expect(r.diastolic, 80);
      expect(r.pulse, isNull);
      expect(r.confidence, lessThan(0.75));
    });

    test('no labels → empty result, zero confidence', () {
      final r = assignByProximity([_n(120, 0, 0)], []);
      expect(r.systolic, isNull);
      expect(r.confidence, 0.0);
    });
  });

  group('assignByPosition (fallback)', () {
    test('largest height → systolic, next → diastolic, smallest → pulse', () {
      final numbers = [
        _n(72, 0, 300, h: 20),
        _n(120, 0, 100, h: 60),
        _n(80, 0, 200, h: 40),
      ];
      final partial = const ScanResult(
        confidence: 0.0,
        source: ScannerType.mlKit,
      );
      final r = assignByPosition(numbers, partial);
      expect(r.systolic, 120);
      expect(r.diastolic, 80);
      expect(r.pulse, 72);
      expect(r.confidence, 0.6);
    });

    test('fewer than 2 numbers → returns partial with low confidence', () {
      final partial = const ScanResult(
        systolic: 130,
        confidence: 0.5,
        source: ScannerType.mlKit,
      );
      final r = assignByPosition([_n(130, 0, 0)], partial);
      expect(r.confidence, 0.3);
    });
  });

  group('combineProximityAndPosition', () {
    test('uses proximity when SYS+DIA present', () {
      final r = combineProximityAndPosition(
        [_n(120, 100, 100), _n(80, 100, 200), _n(72, 100, 300)],
        [
          _l(VitalType.systolic, 30, 100),
          _l(VitalType.diastolic, 30, 200),
          _l(VitalType.pulse, 30, 300),
        ],
      );
      expect(r.systolic, 120);
    });

    test('falls back to positional when no labels', () {
      final r = combineProximityAndPosition(
        [
          _n(120, 0, 100, h: 60),
          _n(80, 0, 200, h: 40),
          _n(72, 0, 300, h: 20),
        ],
        [],
      );
      expect(r.systolic, 120);
      expect(r.diastolic, 80);
      expect(r.pulse, 72);
      expect(r.confidence, 0.6);
    });
  });

  group('ScanResult.isPlausible', () {
    test('rejects implausible values', () {
      const r = ScanResult(
        systolic: 9,
        diastolic: 80,
        pulse: 500,
        confidence: 0.9,
        source: ScannerType.mlKit,
      );
      expect(r.isPlausible, false);
    });
    test('accepts a normal reading', () {
      const r = ScanResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        confidence: 0.9,
        source: ScannerType.mlKit,
      );
      expect(r.isPlausible, true);
      expect(r.isComplete, true);
    });
  });
}
