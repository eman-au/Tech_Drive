import 'package:flutter/material.dart';
import 'package:tech_drive/screens_for_workers/worker_quiz_screen.dart';

class WorkerTestScreen extends StatelessWidget {
  const WorkerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto redirect to REAL quiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WorkerQuizScreen(),
        ),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
