import 'package:flutter/material.dart';

import 'lesson_map_screen.dart';

class ReviewScreen extends StatelessWidget {
  final bool reviewEnabled;
  final VoidCallback onStartTodayReview;

  const ReviewScreen({
    super.key,
    required this.reviewEnabled,
    required this.onStartTodayReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ふくしゅう',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '前にむずかしかったところに近い問題を、あとでもう一度練習できます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                ),
                const SizedBox(height: 28),
                Center(
                  child: TodayReviewCard(
                    enabled: reviewEnabled,
                    onTap: reviewEnabled ? onStartTodayReview : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
