import 'package:flutter/material.dart';
import '../models/lesson.dart';

class RecordsScreen extends StatelessWidget {
  final List<Lesson> lessons;
  final VoidCallback onBack;

  const RecordsScreen({
    super.key,
    required this.lessons,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final completedLessons = lessons.where((lesson) => lesson.completed).length;
    final totalLessons = lessons.length;
    final totalStars = lessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.stars,
    );
    final maxStars = lessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.maxStars,
    );

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
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(
                        child: Text(
                          '学習記録',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        _SummaryCard(
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'クリアしたレッスン',
                          value: '$completedLessons / $totalLessons',
                        ),
                        const SizedBox(height: 12),
                        _SummaryCard(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFEAB308),
                          title: '獲得スター',
                          value: '$totalStars / $maxStars',
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'レッスンごとの進捗',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...lessons.map((lesson) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LessonProgressTile(lesson: lesson),
                          );
                        }),
                      ],
                    ),
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

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonProgressTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonProgressTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lesson.locked
                  ? const Color(0xFFE5E7EB)
                  : lesson.completed
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              lesson.locked
                  ? Icons.lock_rounded
                  : lesson.completed
                  ? Icons.check_rounded
                  : Icons.play_arrow_rounded,
              color: lesson.locked
                  ? const Color(0xFF6B7280)
                  : lesson.completed
                  ? const Color(0xFF15803D)
                  : const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: List.generate(lesson.maxStars, (index) {
              final filled = index < lesson.stars;
              return Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                  color: filled
                      ? const Color(0xFFEAB308)
                      : const Color(0xFFD1D5DB),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
