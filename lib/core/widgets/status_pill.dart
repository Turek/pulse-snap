import 'package:flutter/material.dart';

/// Small Material 3 pill used to surface vital status (BP / HR).
///
/// Renders a rounded container with a colored leading dot, the [label], and
/// either an explicit [backgroundColor] or a derived soft tint of [color].
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;

  /// Compact variant: tighter padding + smaller dot, for dense list rows.
  final bool compact;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final dotSize = compact ? 6.0 : 8.0;
    final textStyle = (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
        ?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}
