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

class _Body extends ConsumerStatefulWidget {
  final HealthPlatformState state;
  final String platformLabel;
  const _Body({required this.state, required this.platformLabel});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _syncing = false;

  HealthPlatformState get state => widget.state;
  String get platformLabel => widget.platformLabel;

  String _subtitle() {
    if (state.pendingPermission) return 'Connecting…';
    if (!state.connected) return 'Not connected';
    if (_syncing) return 'Syncing existing readings…';
    final ts = state.lastSyncAt;
    if (ts == null) return 'Connected';
    return 'Connected — last sync ${DateFormat('MMM d HH:mm').format(ts)}';
  }

  Future<void> _syncExisting() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      final count =
          await ref.read(healthPlatformProvider.notifier).syncExisting();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'All readings were already synced.'
                : 'Synced $count reading${count == 1 ? '' : 's'} to $platformLabel.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(healthPlatformProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.favorite_outline),
          title: Text(platformLabel),
          subtitle: Text(_subtitle()),
          value: state.connected,
          onChanged: state.pendingPermission || !state.available || _syncing
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
                  label: _syncing ? 'Syncing…' : 'Sync past readings',
                  onPressed: _syncing ? null : _syncExisting,
                ),
                const SizedBox(width: 8),
                TextActionButton(
                  label: 'Disconnect',
                  onPressed: _syncing ? null : () => notifier.disconnect(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
