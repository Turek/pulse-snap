import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../settings/settings_provider.dart';
import 'dashboard_provider.dart';
import 'widgets/latest_reading_card.dart';
import 'widgets/trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final hasKey =
        keyAsync.maybeWhen(data: (k) => k.isNotEmpty, orElse: () => false);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('New Reading'),
      ),
      body: Column(
        children: [
          if (!hasKey) const _MissingKeyBanner(),
          Expanded(
            child: stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (s) => !s.hasData
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Latest Reading',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (s.latest != null)
                          LatestReadingCard(reading: s.latest!),
                        const SizedBox(height: 24),
                        Text('Last 30 Days',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TrendChart(readings: s.last30Days),
                        const SizedBox(height: 24),
                        Text('Averages',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _AverageRow(
                          sys: s.avgSys,
                          dia: s.avgDia,
                          pulse: s.avgPulse,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingKeyBanner extends StatelessWidget {
  const _MissingKeyBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => context.push('/settings'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No Gemini API key — OCR will not work',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tap to open Settings.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
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
            const Icon(Icons.monitor_heart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No readings yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the camera button to snap your first reading.',
              textAlign: TextAlign.center,
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
  const _AverageRow({required this.sys, required this.dia, required this.pulse});

  Widget _stat(BuildContext ctx, String label, double v) => Expanded(
        child: Column(
          children: [
            Text(label, style: Theme.of(ctx).textTheme.labelMedium),
            Text(v.toStringAsFixed(0),
                style: Theme.of(ctx).textTheme.headlineSmall),
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
