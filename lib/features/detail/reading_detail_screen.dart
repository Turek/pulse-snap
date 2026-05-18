import 'package:flutter/material.dart';

class ReadingDetailScreen extends StatelessWidget {
  final int readingId;
  const ReadingDetailScreen({super.key, required this.readingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading')),
      body: Center(child: Text('Detail $readingId (Sprint 5)')),
    );
  }
}
