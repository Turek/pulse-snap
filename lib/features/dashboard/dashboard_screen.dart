import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/skeleton.dart';
import 'dashboard_provider.dart';
import 'widgets/latest_reading_card.dart';
import 'widgets/trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PulseSnap'),
      ),
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
                  Text('Latest', style: sectionStyle),
                  const SizedBox(height: 6),
                  if (s.latest != null) LatestReadingCard(reading: s.latest!),
                  const SizedBox(height: 20),
                  Text('Last 30 days', style: sectionStyle),
                  const SizedBox(height: 6),
                  TrendChart(readings: s.last30Days),
                  const SizedBox(height: 20),
                  Text('Averages', style: sectionStyle),
                  const SizedBox(height: 6),
                  _AverageRow(
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

class _AverageRow extends StatelessWidget {
  final double sys;
  final double dia;
  final double pulse;
  const _AverageRow(
      {required this.sys, required this.dia, required this.pulse});

  Widget _stat(BuildContext ctx, String label, double v) => Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              v.toStringAsFixed(0),
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _stat(context, 'SYS', sys),
            _stat(context, 'DIA', dia),
            _stat(context, 'PR', pulse),
          ],
        ),
      ),
    );
  }
}
