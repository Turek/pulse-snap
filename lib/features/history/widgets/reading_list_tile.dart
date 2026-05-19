import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/vital_colors.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tinted_card.dart';
import '../../../domain/health/blood_pressure_status.dart';
import '../../../domain/health/vital_classifiers.dart';
import '../../../domain/tags/reading_with_tags.dart';

class ReadingListTile extends StatelessWidget {
  final ReadingWithTags readingWithTags;
  final VoidCallback? onTap;
  const ReadingListTile({
    super.key,
    required this.readingWithTags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reading = readingWithTags.reading;
    final tags = readingWithTags.tags;

    final sys = reading.systolic;
    final dia = reading.diastolic;
    BloodPressureStatus? bpStatus;
    Color accent = SectionAccent.slate;
    if (sys != null && dia != null) {
      bpStatus = classifyBloodPressure(systolic: sys, diastolic: dia);
      accent = bpStatusColor(bpStatus);
    }

    return TintedCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${reading.systolic ?? '–'} / ${reading.diastolic ?? '–'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.favorite,
                        size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${reading.pulse ?? '–'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (bpStatus != null) ...[
                      const SizedBox(width: 8),
                      StatusPill(
                        label: bpStatus.label,
                        color: bpStatusColor(bpStatus),
                        compact: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reading.measuredAt.formatDateTime(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 22,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tags.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => _TagPill(label: tags[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
