import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_buttons.dart';
import '../health_platform_provider.dart';

class HealthPlatformTile extends ConsumerWidget {
  const HealthPlatformTile({super.key});

  String get _platformLabel =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(healthPlatformProvider);

    return asyncState.when(
      loading: () => ListTile(
        leading: const Icon(Icons.favorite_outline),
        title: Text(_platformLabel),
        subtitle: const Text('Checking…'),
        trailing: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.favorite_outline),
        title: Text(_platformLabel),
        subtitle: Text('Error: $e'),
      ),
      data: (state) => _Body(state: state, platformLabel: _platformLabel),
    );
  }
}

class _Body extends ConsumerWidget {
  final HealthPlatformState state;
  final String platformLabel;
  const _Body({required this.state, required this.platformLabel});

  String _subtitle() {
    if (state.pendingPermission) return 'Connecting…';
    if (!state.connected) return 'Not connected';
    final ts = state.lastSyncAt;
    if (ts == null) return 'Connected';
    return 'Connected — last sync ${DateFormat('MMM d HH:mm').format(ts)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(healthPlatformProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.favorite_outline),
          title: Text(platformLabel),
          subtitle: Text(_subtitle()),
          value: state.connected,
          onChanged: state.pendingPermission || !state.available
              ? null
              : (v) async {
                  if (v) {
                    final ok = await notifier.enable();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permission was not granted.'),
                        ),
                      );
                    }
                  } else {
                    await notifier.disconnect();
                  }
                },
        ),
        if (state.connected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                SecondaryButton(
                  label: 'Sync now',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'All readings are already synced as they are saved.',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                TextActionButton(
                  label: 'Disconnect',
                  onPressed: () => notifier.disconnect(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
