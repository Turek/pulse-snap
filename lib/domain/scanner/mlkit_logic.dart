import 'dart:math';
import 'dart:ui';

import '../models/scan_result.dart';

enum VitalType { systolic, diastolic, pulse }

class NumberBlock {
  final int value;
  final Rect box;
  final double confidence;
  const NumberBlock({
    required this.value,
    required this.box,
    required this.confidence,
  });
}

class LabelBlock {
  final VitalType type;
  final Rect box;
  const LabelBlock({required this.type, required this.box});
}

const _systolicLabels = ['sys', 'syst', 'systolic', 'mmhg'];
const _diastolicLabels = ['dia', 'dias', 'diastolic', 'diast'];
const _pulseLabels = [
  'pulse', 'pr', 'hr', 'heart rate', 'puls', 'bpm',
  '脈拍', '心率', 'nadi',
];

VitalType? classifyLabel(String text) {
  final lower = text.toLowerCase();
  for (final l in _systolicLabels) {
    if (lower.contains(l)) return VitalType.systolic;
  }
  for (final l in _diastolicLabels) {
    if (lower.contains(l)) return VitalType.diastolic;
  }
  for (final l in _pulseLabels) {
    if (lower.contains(l)) return VitalType.pulse;
  }
  return null;
}

double _distance(Rect a, Rect b) {
  final dx = a.center.dx - b.center.dx;
  final dy = a.center.dy - b.center.dy;
  return sqrt(dx * dx + dy * dy);
}

ScanResult assignByProximity(
  List<NumberBlock> numbers,
  List<LabelBlock> labels,
) {
  int? systolic, diastolic, pulse;
  double minConfidence = 1.0;
  final used = <NumberBlock>{};

  final ordered = [
    ...labels.where((l) => l.type == VitalType.systolic),
    ...labels.where((l) => l.type == VitalType.diastolic),
    ...labels.where((l) => l.type == VitalType.pulse),
  ];

  for (final label in ordered) {
    NumberBlock? closest;
    double closestDist = double.infinity;
    for (final n in numbers) {
      if (used.contains(n)) continue;
      final d = _distance(label.box, n.box);
      if (d < closestDist) {
        closestDist = d;
        closest = n;
      }
    }
    if (closest == null) continue;
    used.add(closest);
    minConfidence = min(minConfidence, closest.confidence);
    switch (label.type) {
      case VitalType.systolic:
        systolic ??= closest.value;
      case VitalType.diastolic:
        diastolic ??= closest.value;
      case VitalType.pulse:
        pulse ??= closest.value;
    }
  }

  final found = [systolic, diastolic, pulse].where((v) => v != null).length;
  final confidence = found == 0 ? 0.0 : (found / 3) * minConfidence;

  return ScanResult(
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    confidence: confidence,
    source: ScannerType.mlKit,
  );
}

/// Fallback: tallest detected number → systolic, next → diastolic,
/// remaining → pulse.
ScanResult assignByPosition(
  List<NumberBlock> numbers,
  ScanResult partial,
) {
  if (numbers.length < 2) {
    return partial.copyWith(confidence: 0.3);
  }
  final sorted = [...numbers]
    ..sort((a, b) => b.box.height.compareTo(a.box.height));

  return ScanResult(
    systolic: partial.systolic ?? sorted[0].value,
    diastolic:
        partial.diastolic ?? (sorted.length > 1 ? sorted[1].value : null),
    pulse: partial.pulse ?? (sorted.length > 2 ? sorted[2].value : null),
    confidence: 0.6,
    source: ScannerType.mlKit,
  );
}

ScanResult combineProximityAndPosition(
  List<NumberBlock> numbers,
  List<LabelBlock> labels,
) {
  final byProximity = assignByProximity(numbers, labels);
  if (byProximity.systolic != null && byProximity.diastolic != null) {
    return byProximity;
  }
  return assignByPosition(numbers, byProximity);
}
