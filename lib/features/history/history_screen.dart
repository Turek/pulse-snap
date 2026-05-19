import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/theme/vital_colors.dart';
import '../../core/widgets/gemini_key_action.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tinted_card.dart';
import '../../domain/tags/reading_with_tags.dart';
import '../../providers.dart';
import 'history_provider.dart';
import 'widgets/reading_list_tile.dart';

/// Merged Calendar + History screen. The two-week calendar acts as the
/// date filter; the search bar narrows within the selected day's tags.
/// Reading list lives below, swipe-to-delete with undo.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now().startOfDay;
  CalendarFormat _format = CalendarFormat.month;
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
                  hintText: 'Search tags…',
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
                accent: scheme.primary,
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: TableCalendar<ReadingWithTags>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  rowHeight: 36,
                  daysOfWeekHeight: 18,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2w',
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
                    headerPadding: const EdgeInsets.symmetric(vertical: 4),
                    titleTextStyle: theme.textTheme.titleSmall ?? const TextStyle(),
                    leftChevronPadding: const EdgeInsets.all(4),
                    rightChevronPadding: const EdgeInsets.all(4),
                    leftChevronIcon: Icon(Icons.chevron_left,
                        size: 18, color: scheme.onSurfaceVariant),
                    rightChevronIcon: Icon(Icons.chevron_right,
                        size: 18, color: scheme.onSurfaceVariant),
                    formatButtonDecoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    formatButtonPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    formatButtonTextStyle: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 11,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ) ??
                        const TextStyle(),
                    weekendStyle: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ) ??
                        const TextStyle(),
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(2),
                    cellPadding: EdgeInsets.zero,
                    defaultTextStyle: theme.textTheme.bodySmall ?? const TextStyle(),
                    weekendTextStyle: theme.textTheme.bodySmall ?? const TextStyle(),
                    outsideTextStyle: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.45),
                        ) ??
                        const TextStyle(),
                    selectedTextStyle: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(),
                    todayTextStyle: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer,
                        ) ??
                        const TextStyle(),
                    selectedDecoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 1.5),
                    ),
                    todayDecoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    markersAlignment: Alignment.bottomCenter,
                    markersOffset: const PositionedOffset(bottom: 2),
                  ),
                  calendarBuilders: CalendarBuilders<ReadingWithTags>(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      final status = worstBpStatusOfDay(events);
                      final color = status == null
                          ? scheme.onSurfaceVariant
                          : bpStatusColor(status);
                      // Outline matches the cell background so the dot
                      // doesn't blend into the today/selected ring stroke.
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: scheme.surface,
                            width: 1.2,
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
                          : 'No tags match "$search"',
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
                    key: ValueKey(dayList[i].reading.id),
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
                      readingWithTags: dayList[i],
                      onTap: () =>
                          context.push('/history/${dayList[i].reading.id}'),
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ReadingWithTags rt) {
    final repo = ref.read(readingRepositoryProvider);
    final r = rt.reading;
    final tags = List<String>.from(rt.tags);
    repo.deleteReading(r.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reading deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // id <= 0 lets the repository assign a fresh id.
            repo.saveReading(r.copyWith(id: 0), tags: tags);
          },
        ),
      ),
    );
  }
}
