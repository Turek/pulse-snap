import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/utils/bp_category.dart';
import '../../../data/database/app_database.dart';

class LatestReadingCard extends StatelessWidget {
  final Reading reading;
  const LatestReadingCard({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final cat = bpCategory(reading.systolic, reading.diastolic);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${reading.systolic ?? '–'} / ${reading.diastolic ?? '–'}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cat.color,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.favorite, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  '${reading.pulse ?? '–'}',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(cat.label, style: theme.textTheme.labelLarge?.copyWith(color: cat.color)),
            const SizedBox(height: 4),
            Text(
              reading.measuredAt.formatDateTime(),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
