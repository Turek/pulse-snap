import 'package:flutter/material.dart';

import 'vital_colors.dart';

/// Series colours used in the dashboard line chart. Aligned with DESIGN.md
/// chart line tokens — SYS is the warning-red `vital-bp-high2`, DIA is the
/// sage `tertiary`, Pulse is the dusty-rose secondary tone.
class BpSeriesColors {
  static const systolic = VitalColors.bpHigh2; // #EB5757
  static const diastolic = Color(0xFF49A17A); // tertiary
  static const pulse = Color(0xFFB06885); // dusty rose
}
