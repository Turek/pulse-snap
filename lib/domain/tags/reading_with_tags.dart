import '../../data/database/app_database.dart';

class ReadingWithTags {
  final Reading reading;
  final List<String> tags;

  const ReadingWithTags({
    required this.reading,
    required this.tags,
  });

  bool hasTag(String tag) =>
      tags.any((t) => t.toLowerCase() == tag.toLowerCase());
}
