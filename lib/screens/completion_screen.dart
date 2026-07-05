import 'package:flutter/material.dart';

class CompletionScreen extends StatelessWidget {
  final int stars;
  final int totalQuestions;
  final int correctAnswers;
  final int xpGained;
  final int streak;
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
    required this.xpGained,
    required this.streak,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
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
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFACC15), Color(0xFFF97316)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🏆', style: TextStyle(fontSize: 30)),
                      ),
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
                    'お疲れ様でした',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 350 + index * 90),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            index < stars ? '⭐' : '☆',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _RewardChip(
                          text: '+$xpGained XP',
                          icon: '⚡',
                          backgroundColor: const Color(0xFFEEF2FF),
                          textColor: const Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RewardChip(
                          text: streak <= 1 ? '今日開始' : '$streak日連続',
                          icon: '🔥',
                          backgroundColor: const Color(0xFFFFF7ED),
                          textColor: const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

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
                          '間違えた問題を復習（$wrongQuestionCount問）',
                          style: const TextStyle(
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onNextLesson,
                        child: const Text(
                          '次のレッスンへ',
                          style: TextStyle(
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
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onHome,
                          child: const Text(
                            'ホーム',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onRestart,
                          child: const Text(
                            'もう一度',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String text;
  final String icon;
  final Color backgroundColor;
  final Color textColor;

  const _RewardChip({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          '$icon $text',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
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
