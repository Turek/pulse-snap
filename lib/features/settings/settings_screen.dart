import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../domain/models/scan_result.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('PulseSnap MVP — v1.0.0'),
          ),
          const Divider(),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Seed sample data'),
              subtitle: const Text('Insert 30 synthetic readings'),
              onTap: () async {
                final repo = ref.read(readingRepositoryProvider);
                final now = DateTime.now();
                for (var i = 0; i < 30; i++) {
                  await repo.saveReading(ReadingsCompanion.insert(
                    measuredAt: now.subtract(Duration(days: i)),
                    sourceType: ScannerType.mlKit,
                    systolic: Value(110 + (i % 6) * 5),
                    diastolic: Value(70 + (i % 5) * 4),
                    pulse: Value(65 + (i % 7) * 3),
                    ocrConfidence: const Value(0.9),
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
