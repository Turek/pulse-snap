import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/gemini_key_action.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/database/app_database.dart';
import '../../providers.dart';
import 'history_provider.dart';
import 'widgets/reading_list_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredReadingsProvider);
    final currentFilter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [GeminiKeyAction()],
      ),
      body: filtered.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: 6,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (context, i) => const Skeleton(height: 56, radius: 12),
        ),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (rows) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) =>
                    ref.read(historySearchProvider.notifier).set(v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search notes…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: HistoryFilter.values.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: currentFilter == f,
                      onSelected: (_) => ref
                          .read(historyFilterProvider.notifier)
                          .set(f),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('No readings match'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        return Dismissible(
                          key: ValueKey(r.id),
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _confirmDelete(context, ref, r),
                          child: ReadingListTile(
                            reading: r,
                            onTap: () => context.push('/history/${r.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Reading r) {
    final repo = ref.read(readingRepositoryProvider);
    repo.deleteReading(r.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reading deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            repo.saveReading(ReadingsCompanion.insert(
              measuredAt: r.measuredAt,
              sourceType: r.sourceType,
              systolic: Value(r.systolic),
              diastolic: Value(r.diastolic),
              pulse: Value(r.pulse),
              notes: Value(r.notes),
              ocrConfidence: Value(r.ocrConfidence),
              isManuallyEdited: Value(r.isManuallyEdited),
            ));
          },
        ),
      ),
    );
  }
}
