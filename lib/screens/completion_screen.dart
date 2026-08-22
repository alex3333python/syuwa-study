import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class CompletionScreen extends StatelessWidget {
  final int stars;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongQuestionCount;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback? onNextLesson;
  final VoidCallback? onReview;

  const CompletionScreen({
    super.key,
    required this.stars,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongQuestionCount,
    required this.onRestart,
    required this.onHome,
    required this.onNextLesson,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalQuestions == 0
        ? 0
        : ((correctAnswers / totalQuestions) * 100).round();

    final hasReview = onReview != null && wrongQuestionCount > 0;
    final hasNextLesson = onNextLesson != null;

    return Container(
      width: double.infinity,
      decoration: AppColors.screenBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom + 14,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.75, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFF59E0B),
                      size: 64,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'レッスン完了！',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'おつかれさまでした',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final filled = index < stars;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 350 + index * 90),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 34,
                            color: filled
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD1D5DB),
                            shadows: filled
                                ? const [
                                    Shadow(
                                      color: Color(0x66F59E0B),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ResultMiniBlock(
                            label: '正解率',
                            value: '$percentage%',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          color: const Color(0xFFE5E7EB),
                        ),
                        Expanded(
                          child: _ResultMiniBlock(
                            label: '正解数',
                            value: '$correctAnswers / $totalQuestions',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (hasReview) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onReview,
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(
                          'ふくしゅう（$wrongQuestionCount問）',
                          style: const TextStyle(
                            fontFamily: AppFonts.interface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (hasNextLesson) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onNextLesson,
                        child: const Text(
                          '次のレッスンへ',
                          style: TextStyle(
                            fontFamily: AppFonts.interface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onHome,
                          child: const Text(
                          'ホーム',
                          style: TextStyle(
                            fontFamily: AppFonts.interface,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onRestart,
                          child: const Text(
                          'もう一度',
                          style: TextStyle(
                            fontFamily: AppFonts.interface,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                      ),
                    ],
                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultMiniBlock extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMiniBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
