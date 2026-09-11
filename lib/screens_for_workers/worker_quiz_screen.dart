import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'worker_quiz_result_screen.dart';

class WorkerQuizScreen extends StatefulWidget {
  const WorkerQuizScreen({super.key});

  @override
  State<WorkerQuizScreen> createState() => _WorkerQuizScreenState();
}

class _WorkerQuizScreenState extends State<WorkerQuizScreen> {
  // QUIZ DATA
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int? selectedOption;
  int correctCount = 0;

  // TIMER
  Timer? timer;
  int timeLeft = 30;

  // STATE
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ================= LOAD QUESTIONS =================
  Future<void> _loadQuestions() async {
    try {
      debugPrint("📥 Loading quiz questions...");

      final snap = await FirebaseFirestore.instance
          .collection('worker_quiz')
          .get();

      questions = snap.docs
          .map((e) => e.data())
          .where((e) =>
      e.containsKey('question') &&
          e.containsKey('options') &&
          e.containsKey('correctIndex'))
          .toList()
          .cast<Map<String, dynamic>>();

      debugPrint("✅ Questions loaded: ${questions.length}");

      questions.shuffle();

      setState(() => loading = false);
      _startTimer();
    } catch (e) {
      debugPrint("❌ QUIZ LOAD ERROR: $e");
      setState(() => loading = false);
    }
  }

  // ================= TIMER =================
  void _startTimer() {
    timer?.cancel();
    timeLeft = 30;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 0) {
        _handleTimeUp();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  void _handleTimeUp() {
    timer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Time’s up")),
    );
    _nextQuestion();
  }

  // ================= NEXT QUESTION =================
  void _nextQuestion() {
    timer?.cancel();

    final correctIndex =
        questions[currentIndex]['correctIndex'] ?? -1;

    if (selectedOption == correctIndex) {
      correctCount++;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  // ================= FINISH QUIZ =================
  Future<void> _finishQuiz() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('worker_requests')
          .doc(user.uid)
          .set({
        "userId": user.uid,
        "score": correctCount,
        "total": questions.length,
        "passed": questions.isEmpty
            ? false
            : (correctCount / questions.length) >= 0.6,
        "status": "quiz_completed",
        "completedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerQuizResultScreen(
          score: correctCount,
          total: questions.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Empty quiz safety
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No quiz data found")),
      );
    }

    final q = questions[currentIndex];
    final List options = q['options'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCCFD04),
        title: const Text(
          "Worker Quiz",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// TIMER
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$timeLeft sec",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              color: Colors.green,
            ),

            const SizedBox(height: 24),

            /// QUESTION
            Text(
              q['question']?.toString() ?? 'No Question',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// OPTIONS
            ...List.generate(options.length, (i) {
              final selected = selectedOption == i;

              return GestureDetector(
                onTap: () => setState(() => selectedOption = i),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.green.shade100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    options[i]?.toString() ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
