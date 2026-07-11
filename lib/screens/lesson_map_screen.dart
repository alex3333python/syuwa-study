import 'package:flutter/material.dart';
import '../models/lesson.dart';

class LessonMapScreen extends StatelessWidget {
  final List<Lesson> lessons;
  final void Function(Lesson lesson) onStartLesson;

  const LessonMapScreen({
    super.key,
    required this.lessons,
    required this.onStartLesson,
  });

  @override
  Widget build(BuildContext context) {
    final lessonEntries = _buildLessonEntries(lessons);

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
      child: Stack(
        children: [
          const _BlurCircle(
            size: 260,
            color: Color(0x663B82F6),
            top: 110,
            left: 40,
          ),
          const _BlurCircle(
            size: 260,
            color: Color(0x668B5CF6),
            top: 280,
            right: 20,
          ),
          const _BlurCircle(
            size: 260,
            color: Color(0x66EC4899),
            bottom: 80,
            left: 260,
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calculate_rounded,
                            color: Color(0xFFA855F7),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            '学習マップ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFF59E0B),
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '算数と学校日本語を、ひとつずつ確認しましょう。',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 28),

                    const SizedBox(height: 28),

                    for (int i = 0; i < lessonEntries.length; i++) ...[
                      _LessonRow(
                        item: lessonEntries[i].item,
                        alignLeft: i % 2 == 0,
                        onTap: lessonEntries[i].lessonToStart == null
                            ? null
                            : () => onStartLesson(
                                lessonEntries[i].lessonToStart!,
                              ),
                      ),
                      if (i != lessonEntries.length - 1)
                        const SizedBox(height: 42),
                    ],

                    const SizedBox(height: 48),

                    Container(
                      width: 360,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFF59E0B),
                            size: 64,
                          ),
                          SizedBox(height: 14),
                          Text(
                            '次の単元も準備中',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '診断結果に合わせて練習を増やしていきます。',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_LessonMapEntry> _buildLessonEntries(List<Lesson> lessons) {
    final entries = <_LessonMapEntry>[];
    var addedDivisionUnit = false;
    var addedRemainderUnit = false;

    for (final lesson in lessons) {
      if (_isGrade3DivisionLesson(lesson)) {
        if (addedDivisionUnit) continue;
        addedDivisionUnit = true;

        final divisionLessons = lessons.where(_isGrade3DivisionLesson).toList();
        entries.add(
          _buildUnitEntry(
            unitLessons: divisionLessons,
            title: 'わり算れっすん',
            description: '同じ数ずつ分ける、何こずつ分ける、文章題まで練習します。',
            color1: const Color(0xFF14B8A6),
            color2: const Color(0xFF2563EB),
            restartFromFirstWhenCompleted: true,
            alwaysStartFromFirst: true,
          ),
        );
        continue;
      }

      if (_isGrade3RemainderLesson(lesson)) {
        if (addedRemainderUnit) continue;
        addedRemainderUnit = true;

        final remainderLessons = lessons
            .where(_isGrade3RemainderLesson)
            .toList();
        entries.add(
          _buildUnitEntry(
            unitLessons: remainderLessons,
            title: 'あまりのあるわり算れっすん',
            description: 'あまりの出るわり算と、文章題での答え方を練習します。',
            color1: const Color(0xFFF97316),
            color2: const Color(0xFFDB2777),
          ),
        );
        continue;
      }

      entries.add(
        _LessonMapEntry(
          item: LessonMapItem(
            title: lesson.title,
            description: lesson.description,
            stars: lesson.stars,
            maxStars: lesson.maxStars,
            locked: lesson.locked,
            completed: lesson.completed,
            color1: lesson.id == 1
                ? const Color(0xFF3B82F6)
                : lesson.id == 2
                ? const Color(0xFFA855F7)
                : const Color(0xFFEC4899),
            color2: lesson.id == 1
                ? const Color(0xFF2563EB)
                : lesson.id == 2
                ? const Color(0xFF7C3AED)
                : const Color(0xFFDB2777),
            icon: lesson.id == 1
                ? Icons.fact_check_rounded
                : lesson.id == 2
                ? Icons.call_split_rounded
                : Icons.calculate_rounded,
          ),
          lessonToStart: lesson.locked ? null : lesson,
        ),
      );
    }

    return entries;
  }

  _LessonMapEntry _buildUnitEntry({
    required List<Lesson> unitLessons,
    required String title,
    required String description,
    required Color color1,
    required Color color2,
    bool restartFromFirstWhenCompleted = false,
    bool alwaysStartFromFirst = false,
  }) {
    final allCompleted = unitLessons.every((lesson) => lesson.completed);
    final lessonToStart = unitLessons.where((lesson) {
      return !lesson.locked && !lesson.completed;
    }).firstOrNull;
    final fallbackLesson = unitLessons.where((lesson) {
      return !lesson.locked;
    }).firstOrNull;
    final Lesson? reviewLesson;
    if (unitLessons.isEmpty) {
      reviewLesson = null;
    } else if (restartFromFirstWhenCompleted) {
      reviewLesson = unitLessons.first;
    } else {
      reviewLesson = unitLessons.last;
    }
    final completedCount = unitLessons.where((lesson) {
      return lesson.completed;
    }).length;
    final averageStars = unitLessons.isEmpty
        ? 0
        : (unitLessons.fold<int>(0, (sum, lesson) => sum + lesson.stars) /
                  unitLessons.length)
              .round();

    return _LessonMapEntry(
      item: LessonMapItem(
        title: title,
        description: description,
        stars: averageStars,
        maxStars: 3,
        locked: unitLessons.every((lesson) => lesson.locked),
        completed: allCompleted,
        color1: color1,
        color2: color2,
        icon: Icons.dashboard_customize_rounded,
        subLessons: [
          for (final lesson in unitLessons)
            LessonMapSubItem(
              title: lesson.title,
              locked: lesson.locked,
              completed: lesson.completed,
            ),
        ],
        progressText: '$completedCount / ${unitLessons.length}',
      ),
      lessonToStart: alwaysStartFromFirst
          ? reviewLesson
          : allCompleted
          ? reviewLesson
          : lessonToStart ?? fallbackLesson,
    );
  }

  bool _isGrade3DivisionLesson(Lesson lesson) {
    return lesson.id >= 7 && lesson.id <= 11;
  }

  bool _isGrade3RemainderLesson(Lesson lesson) {
    return lesson.id >= 12 && lesson.id <= 16;
  }
}

class _LessonMapEntry {
  final LessonMapItem item;
  final Lesson? lessonToStart;

  const _LessonMapEntry({required this.item, required this.lessonToStart});
}

class TodayReviewCard extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const TodayReviewCard({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color1 = enabled ? const Color(0xFF14B8A6) : const Color(0xFF9CA3AF);
    final color2 = enabled ? const Color(0xFF2563EB) : const Color(0xFF6B7280);
    final badgeColor = enabled
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF3F4F6);
    final badgeTextColor = enabled
        ? const Color(0xFF166534)
        : const Color(0xFF6B7280);

    return SizedBox(
      width: 430,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: enabled ? 0.94 : 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: enabled
                    ? const Color(0xFF99F6E4)
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: [color1, color2]),
                  ),
                  child: Icon(
                    enabled ? Icons.refresh_rounded : Icons.lock_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今日の復習',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enabled
                            ? '前にむずかしかったところに近い問題を3問練習します。'
                            : '間違えた問題がたまると、ここから復習できます。',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          enabled ? '復習する' : 'まだ準備中',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
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

class LessonMapItem {
  final String title;
  final String description;
  final int stars;
  final int maxStars;
  final bool locked;
  final bool completed;
  final Color color1;
  final Color color2;
  final IconData icon;
  final List<LessonMapSubItem> subLessons;
  final String progressText;

  const LessonMapItem({
    required this.title,
    required this.description,
    required this.stars,
    required this.maxStars,
    required this.locked,
    required this.completed,
    required this.color1,
    required this.color2,
    required this.icon,
    this.subLessons = const [],
    this.progressText = '',
  });
}

class LessonMapSubItem {
  final String title;
  final bool locked;
  final bool completed;

  const LessonMapSubItem({
    required this.title,
    required this.locked,
    required this.completed,
  });
}

class _LessonRow extends StatelessWidget {
  final LessonMapItem item;
  final bool alignLeft;
  final VoidCallback? onTap;

  const _LessonRow({
    required this.item,
    required this.alignLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = _LessonCard(item: item, onTap: onTap);

    return Row(
      mainAxisAlignment: alignLeft
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [SizedBox(width: 390, child: card)],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonMapItem item;
  final VoidCallback? onTap;

  const _LessonCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = item.completed
        ? const Color(0xFF4ADE80)
        : item.locked
        ? const Color(0xFFE5E7EB)
        : const Color(0xFFE5E7EB);

    final cardColor = item.locked
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.90);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LessonIconBox(item: item),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StarRow(
                            stars: item.stars,
                            maxStars: item.maxStars,
                            activeColor: const Color(0xFFEAB308),
                            inactiveColor: const Color(0xFFD1D5DB),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (item.subLessons.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _SubLessonList(items: item.subLessons),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ActionBadge(item: item),
                          if (item.progressText.isNotEmpty)
                            _ProgressPill(text: item.progressText),
                        ],
                      ),
                    ],
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

class _SubLessonList extends StatelessWidget {
  final List<LessonMapSubItem> items;

  const _SubLessonList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _SubLessonTile(item: item),
          if (item != items.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _SubLessonTile extends StatelessWidget {
  final LessonMapSubItem item;

  const _SubLessonTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = item.completed
        ? Icons.check_circle_rounded
        : item.locked
        ? Icons.lock_outline_rounded
        : Icons.play_circle_outline_rounded;
    final color = item.completed
        ? const Color(0xFF16A34A)
        : item.locked
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: item.locked ? const Color(0xFFF9FAFB) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.locked
              ? const Color(0xFFE5E7EB)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                color: item.locked
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String text;

  const _ProgressPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFECFEFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFA5F3FC)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0E7490),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LessonIconBox extends StatelessWidget {
  final LessonMapItem item;

  const _LessonIconBox({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconData = item.locked
        ? Icons.lock_rounded
        : item.completed
        ? Icons.check_rounded
        : item.icon;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [item.color1, item.color2],
        ),
        boxShadow: [
          BoxShadow(
            color: item.color1.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 34),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final LessonMapItem item;

  const _ActionBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.locked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 6),
            Text(
              'ロック中',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (item.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 18,
              color: Color(0xFF15803D),
            ),
            SizedBox(width: 6),
            Text(
              '復習する',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          SizedBox(width: 6),
          Text(
            '始める',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;
  final int maxStars;
  final Color activeColor;
  final Color inactiveColor;

  const _StarRow({
    required this.stars,
    required this.maxStars,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxStars, (index) {
        final filled = index < stars;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? activeColor : inactiveColor,
            size: 24,
          ),
        );
      }),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  const _BlurCircle({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 100, spreadRadius: 25),
            ],
          ),
        ),
      ),
    );
  }
}
