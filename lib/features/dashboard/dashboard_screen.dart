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
  const _AveragesCard(
      {required this.sys, required this.dia, required this.pulse});

  String _v(double v) => v > 0 ? v.toStringAsFixed(0) : '–';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TintedCard(
      accent: SectionAccent.health,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _v(sys),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '/',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Text(
            _v(dia),
            style: theme.textTheme.headlineMedium?.copyWith(
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
            _v(pulse),
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
    );
  }
}
