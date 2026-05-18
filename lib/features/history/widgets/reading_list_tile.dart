import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/utils/bp_category.dart';
import '../../../core/widgets/tinted_card.dart';
import '../../../data/database/app_database.dart';

class ReadingListTile extends StatelessWidget {
  final Reading reading;
  final VoidCallback? onTap;
  const ReadingListTile({super.key, required this.reading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cat = bpCategory(reading.systolic, reading.diastolic);
    final accent = cat == BpCategory.unknown ? SectionAccent.slate : cat.color;

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
                    Icon(Icons.favorite, size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      '${reading.pulse ?? '–'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reading.measuredAt.formatDateTime(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
