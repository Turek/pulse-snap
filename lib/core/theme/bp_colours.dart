import 'package:flutter/material.dart';

import '../utils/bp_category.dart';

/// Series colours used in the dashboard line chart.
class BpSeriesColors {
  static const systolic = Color(0xFF1B6CA8);
  static const diastolic = Color(0xFF1AA39E);
  static const pulse = Color(0xFFEE8434);
}

Color colorForCategory(BpCategory category) => category.color;
