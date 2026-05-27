import 'package:flutter/material.dart';

import '../../../core/theme/vital_colors.dart';
import '../../../domain/tags/reading_with_tags.dart';
import '../history_provider.dart';

/// State a heatmap cell can be in — drives the chip background + text colour.
enum HeatmapCellState { normal, today, selected, outside }

/// One day in the [HistoryScreen] heatmap calendar. The cell background is
/// tinted by the worst BP status recorded that day; a small dot in the
/// corner mirrors that status's colour. Today and the selected day get
/// the standard MD3 chip treatment so they remain readable on any tint.
class CalendarHeatmapCell extends StatelessWidget {
  final DateTime day;
  final List<ReadingWithTags> events;
  final HeatmapCellState state;

  const CalendarHeatmapCell({
    super.key,
    required this.day,
    required this.events,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = events.isEmpty ? null : worstBpStatusOfDay(events);
    final hasEvents = status != null;
    final accent = hasEvents ? bpStatusColor(status) : null;

    // Background tint behind the day chip — always shown when the day has
    // readings, regardless of selected/today state, so the severity colour
    // stays visible.
    final tint = hasEvents ? accent!.withValues(alpha: 0.16) : null;
    final isSelected = state == HeatmapCellState.selected;
    final isToday = state == HeatmapCellState.today;
    final isOutside = state == HeatmapCellState.outside;

    final dayText = '${day.day}';
    final dayStyle = theme.textTheme.bodySmall?.copyWith(
          fontWeight:
              isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isOutside
              ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
              : (isToday
                  ? scheme.onPrimary
                  : (isSelected ? scheme.primary : scheme.onSurface)),
        ) ??
        const TextStyle();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: scheme.primary, width: 1.5)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Today gets a filled primary chip so it stays high-contrast on any tint.
          if (isToday)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          Text(dayText, style: dayStyle),
          if (hasEvents && !isToday)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
