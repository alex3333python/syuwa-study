import 'package:flutter/material.dart';

import '../logic/diagnosis_engine.dart';
import '../models/answer_record.dart';
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
    final strongUnits = result.strongUnits;
    final weakUnits = result.weakUnits;

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
                  'チェックできました',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctAnswers問 / $totalQuestions問 正解',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _ScoreBar(percentage: percentage),
                if (result.unitScores.any((score) => score.total > 0)) ...[
                  const SizedBox(height: 16),
                  _ResultPanel(
                    icon: Icons.grid_view_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: '単元ごとのけっか',
                    child: Column(
                      children: [
                        for (final score in result.unitScores)
                          if (score.total > 0)
                            _UnitScoreRow(score: score),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _ResultPanel(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF16A34A),
                  title: 'よくできている単元',
                  child: strongUnits.isEmpty
                      ? const _MessageRow.watch('今回は、ぜんぶ正解の単元はありませんでした。')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: strongUnits
                              .map(
                                (score) => _MessageRow.good(
                                  '${score.label}（${score.summary}）',
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _ResultPanel(
                  icon: Icons.lightbulb_rounded,
                  iconColor: const Color(0xFFF97316),
                  title: 'つまずいている単元',
                  child: weakUnits.isEmpty
                      ? const _MessageRow.good('大きなつまずきは見つかりませんでした。')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final score in weakUnits)
                              _MessageRow.watch(
                                '${score.label}（${score.summary}）',
                              ),
                            for (final message in _supportMessages())
                              _MessageRow.watch(message),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _ResultPanel(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'おすすめの学習単元',
                  child: recommendedLessons.isEmpty
                      ? const Text(
                          '学習マップから、やってみたいレッスンを選んでください。',
                          style: TextStyle(color: Color(0xFF374151)),
                        )
                      : Column(
                          children: [
                            for (final lesson in recommendedLessons) ...[
                              _RecommendedLessonCard(
                                lesson: lesson,
                                subtitle: _recommendationSubtitle(lesson),
                                onTap: () => onStartRecommendedLesson(lesson),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  onPressed: onHome,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('学習マップにもどる'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _recommendationSubtitle(Lesson lesson) {
    for (final score in result.weakUnits) {
      if (score.entryLessonId == lesson.id) {
        return 'チェック ${score.summary}';
      }
    }
    for (final score in result.unitScores) {
      if (score.entryLessonId == lesson.id && score.total > 0) {
        return 'チェック ${score.summary}';
      }
    }
    if (lesson.description.trim().isNotEmpty) {
      return lesson.description;
    }
    return 'おすすめの単元';
  }

  List<String> _supportMessages() {
    final messages = <String>[];
    final tags = result.tagCounts.keys.toSet();
    final topReason = result.mostCommonMistakeReason;

    if (tags.contains('word_problem') ||
        tags.any((tag) => tag.startsWith('school_japanese_')) ||
        topReason == MistakeReason.wording) {
      messages.add('問題文の言葉や、何を聞かれているかを確かめるとよさそうです。');
    }
    if (tags.contains('unit') || topReason == MistakeReason.unit) {
      messages.add('cm・m・km や g・kg などの単位のことばも、いっしょに確認しましょう。');
    }
    if (tags.contains('round_up_context') ||
        topReason == MistakeReason.askedMeaning) {
      messages.add('あまりをどう使うか（切り上げる / 使わない）を場面で考えましょう。');
    }
    return messages.take(2).toList();
  }
}

class _UnitScoreRow extends StatelessWidget {
  final UnitDiagnosisScore score;

  const _UnitScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final rate = score.rate.clamp(0.0, 1.0);
    final color = score.isStrong
        ? const Color(0xFF16A34A)
        : score.rate == 0
        ? const Color(0xFFDC2626)
        : const Color(0xFFF97316);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  score.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                score.summary,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int percentage;

  const _ScoreBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 14,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'いまの正解率 $percentage%',
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _ResultPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

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
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MessageRow.good(this.text)
    : icon = Icons.check_rounded,
      color = const Color(0xFF16A34A);

  const _MessageRow.watch(this.text)
    : icon = Icons.arrow_right_rounded,
      color = const Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final String subtitle;
  final VoidCallback onTap;

  const _RecommendedLessonCard({
    required this.lesson,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 34,
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
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFEFF6FF),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
