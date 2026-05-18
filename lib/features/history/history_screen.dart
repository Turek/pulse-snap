import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/utils/bp_category.dart';
import '../../core/widgets/gemini_key_action.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tinted_card.dart';
import '../../data/database/app_database.dart';
import '../../providers.dart';
import 'history_provider.dart';
import 'widgets/reading_list_tile.dart';

/// Merged Calendar + History screen. The two-week calendar acts as the
/// date filter; the search bar narrows within the selected day's notes.
/// Reading list lives below, swipe-to-delete with undo.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now().startOfDay;
  CalendarFormat _format = CalendarFormat.twoWeeks;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byDayAsync = ref.watch(readingsByDayProvider);
    final search = ref.watch(historySearchProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sectionStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [GeminiKeyAction()],
      ),
      body: byDayAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Skeleton(height: 320, radius: 20),
        ),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (byDay) {
          final dayList = readingsForDay(
            byDay: byDay,
            day: _selectedDay,
            search: search,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    ref.read(historySearchProvider.notifier).set(v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search notes…',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(historySearchProvider.notifier).set('');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TintedCard(
                accent: SectionAccent.sky,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                child: TableCalendar<Reading>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 weeks',
                    CalendarFormat.week: 'Week',
                  },
                  onFormatChanged: (f) => setState(() => _format = f),
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  onDaySelected: (selected, focused) => setState(() {
                    _selectedDay = selected.startOfDay;
                    _focusedDay = focused;
                  }),
                  eventLoader: (day) => byDay[day.startOfDay] ?? const [],
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: SectionAccent.sky.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: SectionAccent.sky,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: SectionAccent.sky.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders<Reading>(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      final cat = worstCategoryOfDay(events);
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat.color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                DateFormat('EEEE, d MMM').format(_selectedDay).toUpperCase(),
                style: sectionStyle,
              ),
              const SizedBox(height: 8),
              if (dayList.isEmpty)
                TintedCard(
                  accent: SectionAccent.slate,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      search.isEmpty
                          ? 'No readings on this day'
                          : 'No notes match "$search"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                for (var i = 0; i < dayList.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Dismissible(
                    key: ValueKey(dayList[i].id),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        _confirmDelete(context, ref, dayList[i]),
                    child: ReadingListTile(
                      reading: dayList[i],
                      onTap: () =>
                          context.push('/history/${dayList[i].id}'),
                    ),
                  ),
                ],
            ],
          );
        },
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
