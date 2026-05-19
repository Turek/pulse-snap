import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_provider.dart';
import 'widgets/health_platform_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _GeminiApiKeyTile(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export PDF'),
            subtitle: const Text(
                'Doctor-friendly report over a chosen date range.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/export'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Health Platforms',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const HealthPlatformTile(),
          const Divider(),
          const _AboutTile(),
          const Divider(),
        ],
      ),
    );
  }
}

class _AboutTile extends StatefulWidget {
  const _AboutTile();

  @override
  State<_AboutTile> createState() => _AboutTileState();
}

class _AboutTileState extends State<_AboutTile> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snap) {
        final version = snap.data?.version ?? '';
        final subtitle =
            version.isEmpty ? 'PulseSnap' : 'PulseSnap — v$version';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: Text(subtitle),
        );
      },
    );
  }
}

class _GeminiApiKeyTile extends ConsumerStatefulWidget {
  const _GeminiApiKeyTile();

  @override
  ConsumerState<_GeminiApiKeyTile> createState() => _GeminiApiKeyTileState();
}

class _GeminiApiKeyTileState extends ConsumerState<_GeminiApiKeyTile> {
  TextEditingController? _ctrl;
  bool _reveal = false;
  late final TapGestureRecognizer _linkRecognizer = TapGestureRecognizer()
    ..onTap = () => launchUrl(
          Uri.parse('https://aistudio.google.com/apikey'),
          mode: LaunchMode.externalApplication,
        );

  @override
  Widget build(BuildContext context) {
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final current = keyAsync.maybeWhen(data: (k) => k, orElse: () => '');
    _ctrl ??= TextEditingController(text: current);
    final theme = Theme.of(context);
    final bodySmall = theme.textTheme.bodySmall;
    final linkStyle = bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gemini Flash API key',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: bodySmall,
              children: [
                const TextSpan(text: 'Get one free at '),
                TextSpan(
                  text: 'aistudio.google.com/apikey',
                  style: linkStyle,
                  recognizer: _linkRecognizer,
                ),
                const TextSpan(
                  text: '. When set, BP readings are extracted via Gemini '
                      'Flash instead of on-device OCR. The photo is uploaded '
                      'to Google for that single request.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: !_reveal,
            decoration: InputDecoration(
              labelText: 'API key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_reveal ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _reveal = !_reveal),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (current.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await ref.read(geminiApiKeyProvider.notifier).set('');
                    _ctrl!.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key cleared')),
                      );
                    }
                  },
                  child: const Text('Clear'),
                ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(geminiApiKeyProvider.notifier)
                      .set(_ctrl!.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Key saved')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _linkRecognizer.dispose();
    super.dispose();
  }
}
