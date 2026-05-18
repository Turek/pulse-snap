import 'package:flutter/material.dart';

enum BpCategory {
  unknown,
  normal,
  elevated,
  stage1,
  stage2,
  crisis,
}

extension BpCategoryX on BpCategory {
  String get label {
    switch (this) {
      case BpCategory.unknown:
        return 'Unknown';
      case BpCategory.normal:
        return 'Normal';
      case BpCategory.elevated:
        return 'Elevated';
      case BpCategory.stage1:
        return 'High Stage 1';
      case BpCategory.stage2:
        return 'High Stage 2';
      case BpCategory.crisis:
        return 'Hypertensive Crisis';
    }
  }

  Color get color {
    switch (this) {
      case BpCategory.unknown:
        return Colors.grey;
      case BpCategory.normal:
        return Colors.green;
      case BpCategory.elevated:
        return Colors.amber;
      case BpCategory.stage1:
        return Colors.orange;
      case BpCategory.stage2:
        return Colors.red;
      case BpCategory.crisis:
        return Colors.red.shade900;
    }
  }
}

/// Classifies a BP reading per AHA guidelines (2017).
/// Crisis takes precedence; otherwise the higher of the two values wins.
BpCategory bpCategory(int? systolic, int? diastolic) {
  if (systolic == null || diastolic == null) return BpCategory.unknown;
  if (systolic > 180 || diastolic > 120) return BpCategory.crisis;
  if (systolic >= 140 || diastolic >= 90) return BpCategory.stage2;
  if (systolic >= 130 || diastolic >= 80) return BpCategory.stage1;
  if (systolic >= 120 && diastolic < 80) return BpCategory.elevated;
  if (systolic < 120 && diastolic < 80) return BpCategory.normal;
  return BpCategory.unknown;
}
