import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/vital_colors.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/tinted_card.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/health/blood_pressure_status.dart';
import '../../../domain/health/heart_rate_status.dart';
import '../../../domain/health/vital_classifiers.dart';

class LatestReadingCard extends StatelessWidget {
  final Reading reading;
  const LatestReadingCard({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final sys = reading.systolic;
    final dia = reading.diastolic;
    final pulse = reading.pulse;

    BloodPressureStatus? bpStatus;
    Color accent = SectionAccent.sky;
    if (sys != null && dia != null) {
      bpStatus = classifyBloodPressure(systolic: sys, diastolic: dia);
      accent = bpStatusColor(bpStatus);
    }

    HeartRateStatus? hrStatus;
    if (pulse != null) {
      hrStatus = classifyHeartRate(bpm: pulse);
    }

    return TintedCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${reading.systolic ?? '–'}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '/',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Text(
                '${reading.diastolic ?? '–'}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'mmHg',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.favorite, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${reading.pulse ?? '–'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'bpm',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (bpStatus != null || hrStatus != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (bpStatus != null)
                  StatusPill(
                    label: bpStatus.label,
                    color: bpStatusColor(bpStatus),
                  ),
                if (hrStatus != null)
                  StatusPill(
                    label: 'Pulse · ${hrStatus.label}',
                    color: hrStatusColor(hrStatus),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                reading.measuredAt.formatDateTime(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
