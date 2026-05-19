import 'package:flutter/material.dart';

import '../../domain/health/blood_pressure_status.dart';
import '../../domain/health/heart_rate_status.dart';
import '../../domain/health/severity_level.dart';

@immutable
class VitalColors {
  static const bpLow = Color(0xFF2F80ED);
  static const bpNormal = Color(0xFF27AE60);
  static const bpElevated = Color(0xFFF2C94C);
  static const bpHigh1 = Color(0xFFF2994A);
  static const bpHigh2 = Color(0xFFEB5757);
  static const bpCrisis = Color(0xFF8B1E3F);

  static const hrVeryLow = Color(0xFF3F8CFF);
  static const hrLow = Color(0xFF56CCF2);
  static const hrNormal = Color(0xFF27AE60);
  static const hrHigh1 = Color(0xFFF2C94C);
  static const hrHigh2 = Color(0xFFF2994A);
  static const hrHigh3 = Color(0xFFEB5757);

  static const infoBg = Color(0xFFEAF3FF);
  static const successBg = Color(0xFFEAF8EF);
  static const cautionBg = Color(0xFFFFF7E0);
  static const warningBg = Color(0xFFFFEFE2);
  static const dangerBg = Color(0xFFFDECEC);
  static const urgentBg = Color(0xFFF8E6EC);
}

/// Foreground/accent color for a BP status pill.
Color bpStatusColor(BloodPressureStatus status) {
  switch (status) {
    case BloodPressureStatus.low:
      return VitalColors.bpLow;
    case BloodPressureStatus.normal:
      return VitalColors.bpNormal;
    case BloodPressureStatus.elevated:
      return VitalColors.bpElevated;
    case BloodPressureStatus.highStage1:
      return VitalColors.bpHigh1;
    case BloodPressureStatus.highStage2:
      return VitalColors.bpHigh2;
    case BloodPressureStatus.crisis:
      return VitalColors.bpCrisis;
  }
}

/// Foreground/accent color for an HR status pill.
Color hrStatusColor(HeartRateStatus status) {
  switch (status) {
    case HeartRateStatus.veryLow:
      return VitalColors.hrVeryLow;
    case HeartRateStatus.low:
      return VitalColors.hrLow;
    case HeartRateStatus.normal:
      return VitalColors.hrNormal;
    case HeartRateStatus.mildlyHigh:
      return VitalColors.hrHigh1;
    case HeartRateStatus.high:
      return VitalColors.hrHigh2;
    case HeartRateStatus.veryHigh:
      return VitalColors.hrHigh3;
  }
}

/// Soft background color for a chip/banner at a given severity.
Color severityBackground(SeverityLevel level) {
  switch (level) {
    case SeverityLevel.info:
      return VitalColors.infoBg;
    case SeverityLevel.normal:
      return VitalColors.successBg;
    case SeverityLevel.caution:
      return VitalColors.cautionBg;
    case SeverityLevel.warning:
      return VitalColors.warningBg;
    case SeverityLevel.danger:
      return VitalColors.dangerBg;
    case SeverityLevel.urgent:
      return VitalColors.urgentBg;
  }
}
