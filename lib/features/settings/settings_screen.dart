import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../domain/models/scan_result.dart';
import '../../providers.dart';
import 'settings_provider.dart';

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
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('PulseSnap MVP — v1.0.0'),
          ),
          const Divider(),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Insert 30 demo readings (debug)'),
              subtitle: const Text(
                  'Populates the local DB with fake history. Not OCR training data.'),
              onTap: () async {
                final repo = ref.read(readingRepositoryProvider);
                final now = DateTime.now();
                for (var i = 0; i < 30; i++) {
                  final at = now.subtract(Duration(days: i));
                  await repo.saveReading(Reading(
                    id: 0,
                    userId: 'default',
                    measuredAt: at,
                    sourceType: ScannerType.mlKit,
                    systolic: 110 + (i % 6) * 5,
                    diastolic: 70 + (i % 5) * 4,
                    pulse: 65 + (i % 7) * 3,
                    ocrConfidence: 0.9,
                    isManuallyEdited: false,
                    createdAt: at,
                  ));
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seeded 30 readings')),
                  );
                }
              },
            ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final current = keyAsync.maybeWhen(data: (k) => k, orElse: () => '');
    _ctrl ??= TextEditingController(text: current);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gemini Flash API key',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Get one free at aistudio.google.com/apikey. When set, BP '
            'readings are extracted via Gemini Flash instead of on-device '
            'OCR. The photo is uploaded to Google for that single request.',
            style: Theme.of(context).textTheme.bodySmall,
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
    super.dispose();
  }
}
