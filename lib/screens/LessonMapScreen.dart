import 'package:flutter/material.dart';

class LessonMapScreen extends StatelessWidget {
  final VoidCallback onStart;

  const LessonMapScreen({
    super.key,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final lessons = [
      const LessonMapItem(
        title: '挨拶の基本',
        description: 'こんにちは、ありがとう、さようなら',
        stars: 3,
        maxStars: 3,
        locked: false,
        completed: true,
        color1: Color(0xFF3B82F6),
        color2: Color(0xFF2563EB),
        icon: Icons.check,
      ),
      const LessonMapItem(
        title: '自己紹介',
        description: '名前、年齢、出身地',
        stars: 2,
        maxStars: 3,
        locked: false,
        completed: false,
        color1: Color(0xFFA855F7),
        color2: Color(0xFF7C3AED),
        icon: Icons.check,
      ),
      const LessonMapItem(
        title: '日常の言葉',
        description: 'はい、いいえ、お願いします',
        stars: 0,
        maxStars: 3,
        locked: true,
        completed: false,
        color1: Color(0xFFEC4899),
        color2: Color(0xFFDB2777),
        icon: Icons.pan_tool_alt_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFF5F3FF),
            Color(0xFFFDF2F8),
          ],
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
                        color: Colors.white.withOpacity(0.88),
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
                            Icons.front_hand_rounded,
                            color: Color(0xFFA855F7),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            '手話の旅',
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
                      '一歩ずつ、手話の世界を冒険しよう',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 56),

                    for (int i = 0; i < lessons.length; i++) ...[
                      _LessonRow(
                        item: lessons[i],
                        alignLeft: i % 2 == 0,
                        onTap: lessons[i].locked ? null : onStart,
                      ),
                      if (i != lessons.length - 1)
                        const SizedBox(height: 42),
                    ],

                    const SizedBox(height: 48),

                    Container(
                      width: 360,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
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
                            'もっと学習を続けよう！',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '新しいレベルが近日公開予定',
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
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 390,
          child: card,
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonMapItem item;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = item.completed
        ? const Color(0xFF4ADE80)
        : item.locked
            ? const Color(0xFFE5E7EB)
            : const Color(0xFF4ADE80);

    final cardColor = item.locked
        ? Colors.white.withOpacity(0.72)
        : Colors.white.withOpacity(0.9);

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
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
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
                      const SizedBox(height: 16),
                      _ActionBadge(item: item),
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
            color: item.color1.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 34,
      ),
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
            Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF6B7280)),
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
            Icon(Icons.emoji_events_outlined, size: 18, color: Color(0xFF15803D)),
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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
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
              BoxShadow(
                color: color,
                blurRadius: 100,
                spreadRadius: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}