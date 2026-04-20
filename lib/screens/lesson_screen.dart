/*
[lesson_screen.dart]

pur: レッスン画面に特化したUIを構築する．

*/

import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/question.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final void Function({
    required int stars,
    required int correctAnswers,
    required int totalQuestions,
  }) onComplete;
  final VoidCallback onClose;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.onComplete,
    required this.onClose,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool showFeedback = false;
  int correctCount = 0;

  Question get currentQuestion => widget.lesson.questions[currentQuestionIndex];

  void handleAnswerSelect(int answerIndex) {
    if (showFeedback) return;

    setState(() {
      selectedAnswer = answerIndex;
      showFeedback = true;

      if (answerIndex == currentQuestion.correctAnswer) {
        correctCount++;
      }
    });
  }

  void handleNext() {
    if (currentQuestionIndex < widget.lesson.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        showFeedback = false;
      });
    } else {
      final totalQuestions = widget.lesson.questions.length;
      final stars = ((correctCount / totalQuestions) * 3).ceil();

      widget.onComplete(
        stars: stars,
        correctAnswers: correctCount,
        totalQuestions: totalQuestions,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = currentQuestion.options;
    final correctAnswer = currentQuestion.correctAnswer;
    final isCorrect = selectedAnswer == correctAnswer;
    final progress = (currentQuestionIndex + 1) / widget.lesson.questions.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${currentQuestionIndex + 1} / ${widget.lesson.questions.length}'),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  currentQuestion.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  currentQuestion.signDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.builder(
                    itemCount: options.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, index) {
                      final isSelected = selectedAnswer == index;
                      final isCorrectOption = index == correctAnswer;

                      Color bgColor = Colors.white;
                      Color borderColor = const Color(0xFFE5E7EB);
                      // 正解，不正解の表示，解説
                      if (showFeedback) {
                        if (isSelected && isCorrect) {
                          bgColor = const Color(0xFFDCFCE7);
                          borderColor = const Color(0xFF22C55E);
                        } else if (isSelected && !isCorrect) {
                          bgColor = const Color(0xFFFEE2E2);
                          borderColor = const Color(0xFFEF4444);
                        } else if (isCorrectOption) {
                          bgColor = const Color(0xFFDCFCE7);
                          borderColor = const Color(0xFF22C55E);
                        }
                      }

                      return InkWell(
                        onTap: showFeedback ? null : () => handleAnswerSelect(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              options[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showFeedback)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              border: Border(
                top: BorderSide(
                  color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isCorrect
                        ? '正解です！'
                        : '不正解です。正解は「${options[correctAnswer]}」です',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: handleNext,
                  child: Text(
                    currentQuestionIndex < widget.lesson.questions.length - 1
                        ? '次へ'
                        : '完了',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}