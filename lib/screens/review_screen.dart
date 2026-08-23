import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../services/favorite_vocabulary_store.dart';
import '../theme/app_colors.dart';
import 'lesson_map_screen.dart';
import 'word_review_screen.dart';

class ReviewScreen extends StatelessWidget {
  final bool reviewEnabled;
  final VoidCallback onStartTodayReview;
  final AppLanguage language;

  const ReviewScreen({
    super.key,
    required this.reviewEnabled,
    required this.onStartTodayReview,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppColors.screenBackground,
      child: ListenableBuilder(
        listenable: FavoriteVocabularyStore.instance,
        builder: (context, _) {
          final favoriteCount = FavoriteVocabularyStore.instance.count;
          return SingleChildScrollView(
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
                    const SizedBox(height: 18),
                    Center(
                      child: _WordReviewCard(
                        enabled: favoriteCount > 0,
                        wordCount: favoriteCount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WordReviewScreen(
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WordReviewCard extends StatelessWidget {
  final bool enabled;
  final int wordCount;
  final VoidCallback onTap;

  const _WordReviewCard({
    required this.enabled,
    required this.wordCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color1 = enabled ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF);
    final color2 = enabled ? const Color(0xFFEA580C) : const Color(0xFF6B7280);
    final badgeColor =
        enabled ? const Color(0xFFFFF7ED) : const Color(0xFFF3F4F6);
    final badgeTextColor =
        enabled ? const Color(0xFF9A3412) : const Color(0xFF6B7280);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: enabled ? 0.94 : 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: enabled
                    ? const Color(0xFFFDE68A)
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
                    enabled ? Icons.star_rounded : Icons.star_border_rounded,
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
                        'ことばのふくしゅう',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enabled
                            ? 'むずかしいことばをふくしゅうしよう'
                            : '辞書で★をつけたことばが、ここにたまります。',
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
                          enabled ? '$wordCountご' : 'まだないよ',
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
