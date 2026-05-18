import 'dart:io';

import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final File? imageFile;
  const ReviewScreen({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: const Center(child: Text('Review (Sprint 3)')),
    );
  }
}
