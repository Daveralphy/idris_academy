import 'package:flutter/material.dart';

class PracticeExamsPage extends StatelessWidget {
  const PracticeExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Exams'),
      ),
      body: const Center(
        child: Text('CBT test options will be available here.'),
      ),
    );
  }
}