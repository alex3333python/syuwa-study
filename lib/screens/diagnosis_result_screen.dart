import 'package:flutter/material.dart';

import '../logic/diagnosis_engine.dart';
import '../models/lesson.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final DiagnosisResult result;
  final List<Lesson> recommendedLessons;
  final int totalQuestions;
  final int correctAnswers;
  final VoidCallback onHome;
  final void Function(Lesson lesson) onStartRecommendedLesson;

  const DiagnosisResultScreen({
    super.key,
    required this.result,
    required this.recommendedLessons,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.onHome,
    required this.onStartRecommendedLesson,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalQuestions == 0
        ? 0
        : ((correctAnswers / totalQuestions) * 100).round();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '診断結果',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '正答率 $percentage%  |  $correctAnswers / $totalQuestions',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                _ResultPanel(
                  title: '見えてきたつまずき',
                  child: result.hasWeakness
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: result.weakTags
                              .map(_WeakTagChip.new)
                              .toList(),
                        )
                      : const Text(
                          '大きなつまずきは見つかりませんでした。次の練習に進めます。',
                          style: TextStyle(color: Color(0xFF374151)),
                        ),
                ),
                const SizedBox(height: 16),
                _ResultPanel(
                  title: 'おすすめレッスン',
                  child: recommendedLessons.isEmpty
                      ? const Text(
                          '学習マップから好きなレッスンを選んでください。',
                          style: TextStyle(color: Color(0xFF374151)),
                        )
                      : Column(
                          children: [
                            for (final lesson in recommendedLessons) ...[
                              _RecommendedLessonCard(
                                lesson: lesson,
                                onTap: () => onStartRecommendedLesson(lesson),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('学習マップへ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ResultPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WeakTagChip extends StatelessWidget {
  final String tag;

  const _WeakTagChip(this.tag);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_tagLabel(tag)),
      backgroundColor: const Color(0xFFFFF7ED),
      side: const BorderSide(color: Color(0xFFFED7AA)),
      labelStyle: const TextStyle(
        color: Color(0xFF9A3412),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _tagLabel(String tag) {
    switch (tag) {
      case 'division':
        return 'わり算';
      case 'multiplication':
        return 'かけ算';
      case 'subtraction':
        return 'ひき算';
      case 'word_problem':
        return '文章題';
      case 'school_japanese_equally':
        return '「同じ数ずつ」';
      case 'school_japanese_each':
        return '「ずつ」';
      case 'school_japanese_remaining':
        return '「残り」';
      case 'school_japanese_more_than':
        return '「より」';
      default:
        return tag;
    }
  }
}

class _RecommendedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _RecommendedLessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
