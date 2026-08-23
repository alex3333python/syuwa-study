import 'package:flutter/material.dart';

import '../data/audio_cues.dart';
import '../data/learning_language_support.dart';
import '../models/app_language.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/favorite_vocabulary_store.dart';
import '../theme/app_colors.dart';

/// Flip-through review of words the learner starred in the dictionary.
class WordReviewScreen extends StatelessWidget {
  final AppLanguage language;

  const WordReviewScreen({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final store = FavoriteVocabularyStore.instance;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppColors.screenBackground,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final words = store.favorites;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'もどる',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'ことばのふくしゅう',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Text(
                      words.isEmpty
                          ? 'まだお気に入りのことばがありません。レッスンの辞書で ★ をつけてみよう。'
                          : 'むずかしいことばをふくしゅうしよう（${words.length}ご）',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Expanded(
                    child: words.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.star_border_rounded,
                              size: 72,
                              color: Color(0xFFD1D5DB),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                            itemCount: words.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final entry = words[index];
                              return _FavoriteWordCard(
                                entry: entry,
                                language: language,
                                onToggleFavorite: () {
                                  unawaitedToggle(store, entry);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void unawaitedToggle(FavoriteVocabularyStore store, VocabularyEntry entry) {
    store.toggle(entry);
  }
}

class _FavoriteWordCard extends StatelessWidget {
  final VocabularyEntry entry;
  final AppLanguage language;
  final VoidCallback onToggleFavorite;

  const _FavoriteWordCard({
    required this.entry,
    required this.language,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final nativeMeaning = nativeMeaningFor(entry, language);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE68A), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  entry.term,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                tooltip: '音声',
                onPressed: () {
                  LearningAudio.play(
                    context,
                    AudioCueFactory.vocabulary(
                      term: entry.term,
                      reading: entry.reading,
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'お気に入り解除',
                onPressed: onToggleFavorite,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFBEB),
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                ),
                icon: const Icon(Icons.star_rounded),
              ),
            ],
          ),
          if (entry.reading.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entry.reading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          if (entry.simpleJapanese.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.simpleJapanese,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
          if (language != AppLanguage.japanese &&
              nativeMeaning.isNotEmpty &&
              nativeMeaning != entry.simpleJapanese &&
              !looksLikeJapaneseGloss(nativeMeaning)) ...[
            const SizedBox(height: 8),
            Text(
              nativeMeaning,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          if (entry.exampleSentence.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.exampleSentence,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
