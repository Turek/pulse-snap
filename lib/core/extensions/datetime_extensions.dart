import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String formatShort() => DateFormat('dd MMM').format(this);
  String formatTime() => DateFormat('HH:mm').format(this);
  String formatDateTime() => DateFormat('dd MMM, HH:mm').format(this);
  DateTime get startOfDay => DateTime(year, month, day);
}
