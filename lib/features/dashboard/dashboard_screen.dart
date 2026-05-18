import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tinted_card.dart';
import 'dashboard_provider.dart';
import 'widgets/latest_reading_card.dart';
import 'widgets/trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('PulseSnap')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('New Reading'),
      ),
      body: stats.when(
        loading: () => const DashboardSkeleton(),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (s) => !s.hasData
            ? const _EmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  Text('LATEST', style: sectionStyle),
                  const SizedBox(height: 8),
                  if (s.latest != null) LatestReadingCard(reading: s.latest!),
                  const SizedBox(height: 24),
                  Text('LAST 30 DAYS', style: sectionStyle),
                  const SizedBox(height: 8),
                  TrendChart(readings: s.last30Days),
                  const SizedBox(height: 24),
                  Text('AVERAGES', style: sectionStyle),
                  const SizedBox(height: 8),
                  _AveragesCard(
                    sys: s.avgSys,
                    dia: s.avgDia,
                    pulse: s.avgPulse,
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No readings yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the camera button to snap your first reading.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AveragesCard extends StatelessWidget {
  final double sys;
  final double dia;
  final double pulse;
  const _AveragesCard({required this.sys, required this.dia, required this.pulse});

  Widget _stat(BuildContext ctx, String label, double v) => Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              v > 0 ? v.toStringAsFixed(0) : '–',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      accent: SectionAccent.health,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _stat(context, 'SYS', sys),
          _stat(context, 'DIA', dia),
          _stat(context, 'PR', pulse),
        ],
      ),
    );
  }
}
