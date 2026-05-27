import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import 'settings_provider.dart';
import 'widgets/health_platform_tile.dart';

/// Settings — sectioned per DESIGN.md:
///   CLOUD OCR     → Gemini Flash API key (with link + status dot)
///   INTEGRATIONS  → Apple Health / Health Connect tile
///   DATA          → Export to PDF
///   ABOUT         → version
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionStyle = AppTextStyles.sectionCaps(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(label: 'CLOUD OCR', style: sectionStyle),
          const _GeminiApiKeyTile(),

          const Divider(height: 24),

          _SectionHeader(label: 'INTEGRATIONS', style: sectionStyle),
          const HealthPlatformTile(),

          const Divider(height: 24),

          _SectionHeader(label: 'DATA', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export to PDF'),
            subtitle: const Text('Pick a date range, preview and share'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/export'),
          ),

          const Divider(height: 24),

          _SectionHeader(label: 'ABOUT', style: sectionStyle),
          const _AboutTile(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final TextStyle? style;
  const _SectionHeader({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(label, style: style),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final current = keyAsync.maybeWhen(data: (k) => k, orElse: () => '');
    _ctrl ??= TextEditingController(text: current);
    final hasKey = current.isNotEmpty;
    final bodySmall = theme.textTheme.bodySmall;
    final linkStyle = bodySmall?.copyWith(
      color: scheme.primary,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gemini Flash API key', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasKey ? scheme.tertiary : scheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasKey
                      ? 'Key set · Gemini Flash active'
                      : 'No key · using on-device OCR',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        hasKey ? scheme.tertiary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (hasKey)
                TextActionButton(
                  label: 'Clear',
                  onPressed: () async {
                    await ref.read(geminiApiKeyProvider.notifier).set('');
                    _ctrl!.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key cleared')),
                      );
                    }
                  },
                ),
              const SizedBox(width: 8),
              PrimaryButton(
                label: 'Save',
                icon: Icons.check,
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
