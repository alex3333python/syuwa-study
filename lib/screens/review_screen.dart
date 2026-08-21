import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
      decoration: AppColors.screenBackground,
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
