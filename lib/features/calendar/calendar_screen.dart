import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/extensions/datetime_extensions.dart';
import '../../core/utils/bp_category.dart';
import '../../data/database/app_database.dart';
import '../history/widgets/reading_list_tile.dart';
import 'calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final grouped = ref.watch(calendarReadingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: grouped.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (byDay) {
          final selected = _selectedDay?.startOfDay;
          final dayReadings =
              selected == null ? const <Reading>[] : (byDay[selected] ?? const <Reading>[]);
          return Column(
            children: [
              TableCalendar<Reading>(
                firstDay: DateTime(2020),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    _selectedDay != null && isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                eventLoader: (day) => byDay[day.startOfDay] ?? const [],
                calendarBuilders: CalendarBuilders<Reading>(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final cat = worstCategoryOfDay(events);
                    return Positioned(
                      bottom: 6,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cat.color,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: dayReadings.isEmpty
                    ? const Center(child: Text('No readings on this day.'))
                    : ListView.separated(
                        itemCount: dayReadings.length,
                        separatorBuilder: (context, i) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = dayReadings[i];
                          return ReadingListTile(
                            reading: r,
                            onTap: () => context.push('/history/${r.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
