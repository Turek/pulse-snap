import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/utils/bp_category.dart';
import '../../../data/database/app_database.dart';

class ReadingListTile extends StatelessWidget {
  final Reading reading;
  final VoidCallback? onTap;
  const ReadingListTile({super.key, required this.reading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = bpCategory(reading.systolic, reading.diastolic);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: cat.color,
        radius: 10,
      ),
      title: Text(
        '${reading.systolic ?? '–'} / ${reading.diastolic ?? '–'}   ❤ ${reading.pulse ?? '–'}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(reading.measuredAt.formatDateTime()),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
