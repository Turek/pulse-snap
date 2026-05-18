import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/settings_provider.dart';

/// AppBar action that surfaces Gemini API key status: shows a red dot
/// badge when the key is missing, regular icon when it's set. Tap routes
/// to Settings.
class GeminiKeyAction extends ConsumerWidget {
  const GeminiKeyAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final hasKey =
        keyAsync.maybeWhen(data: (k) => k.isNotEmpty, orElse: () => false);
    return IconButton(
      tooltip: hasKey ? 'Gemini key configured' : 'Add Gemini API key',
      onPressed: () => context.push('/settings'),
      icon: Badge(
        isLabelVisible: !hasKey,
        smallSize: 8,
        backgroundColor: Theme.of(context).colorScheme.error,
        child: Icon(hasKey ? Icons.key : Icons.key_off_outlined),
      ),
    );
  }
}
