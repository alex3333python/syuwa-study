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
    final strengths = _strengthMessages();

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
                const SizedBox(height: 24),
                _ResultPanel(
                  icon: Icons.check_circle_rounded,
                  iconColor: Color(0xFF16A34A),
                  title: 'できていること',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: strengths
                        .map((message) => _MessageRow.good(message))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _ResultPanel(
                  icon: Icons.lightbulb_rounded,
                  iconColor: Color(0xFFF97316),
                  title: 'つまずいているかもしれないこと',
                  child: result.hasWeakness
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: result.weakTags
                              .map(
                                (tag) => _MessageRow.watch(
                                  _childFriendlyTagMessage(tag),
                                ),
                              )
                              .toList(),
                        )
                      : const _MessageRow.good('大きなつまずきは見つかりませんでした。'),
                ),
                const SizedBox(height: 16),
                _ResultPanel(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: Color(0xFF2563EB),
                  title: '次にやってみよう',
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
                                onTap: () => onStartRecommendedLesson(lesson),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
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

  List<String> _strengthMessages() {
    final messages = <String>[];

    if (correctAnswers > 0) {
      messages.add('自分で考えて、答えを選べています。');
    }
    if (!result.tagCounts.containsKey('place_value')) {
      messages.add('数の位を読む問題はよくできています。');
    }
    if (!result.tagCounts.containsKey('word_problem')) {
      messages.add('文章題の場面を読み取れています。');
    }
    if (messages.isEmpty) {
      messages.add('まずは最後までチェックに取り組めました。');
    }

    return messages.take(3).toList();
  }

  String _childFriendlyTagMessage(String tag) {
    switch (tag) {
      case 'division':
        return '同じ数に分けるとき、わり算を使うところ。';
      case 'multiplication':
        return '同じ数が何人分・何こ分あるかを考えるところ。';
      case 'subtraction':
        return '残りやちがいを、ひき算で考えるところ。';
      case 'comparison':
        return '「どちらがどれだけ多い・長い」をくらべるところ。';
      case 'fraction':
        return '分数の大きさをくらべるところ。';
      case 'word_problem':
        return '文を読んで、どんな計算かを選ぶところ。';
      case 'school_japanese_equally':
        return '「同じ数ずつ分ける」という学校の言い方。';
      case 'school_japanese_each':
        return '「ずつ」という言葉の意味。';
      case 'school_japanese_remaining':
        return '「残り」という言葉の意味。';
      case 'school_japanese_more_than':
        return '「より」というくらべる言葉の意味。';
      default:
        return tag;
    }
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
  final VoidCallback onTap;

  const _RecommendedLessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
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
                      lesson.description,
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
