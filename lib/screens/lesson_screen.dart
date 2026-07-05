import 'package:flutter/material.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../widgets/sign_video_player.dart';
import '../widgets/tappable_sentence.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Future<void> Function({
    required int stars,
    required int correctAnswers,
    required int totalQuestions,
    required List<Question> wrongQuestions,
    required List<Question> correctQuestions,
  })
  onComplete;
  final VoidCallback onClose;
  final AppLanguage selectedLanguage;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.onComplete,
    required this.onClose,
    this.selectedLanguage = AppLanguage.japanese,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool showFeedback = false;
  int correctCount = 0;
  List<Question> wrongQuestions = [];
  List<Question> correctQuestions = [];
  QuestionPromptMode promptMode = QuestionPromptMode.schoolJa;

  Question get currentQuestion => widget.lesson.questions[currentQuestionIndex];

  void handleAnswerSelect(int answerIndex) {
    if (showFeedback) return;

    setState(() {
      selectedAnswer = answerIndex;
      showFeedback = true;

      if (answerIndex == currentQuestion.correctAnswer) {
        correctCount++;
        correctQuestions.add(currentQuestion);
      } else {
        wrongQuestions.add(currentQuestion);
      }
    });
  }

  Future<void> handleNext() async {
    if (currentQuestionIndex < widget.lesson.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        showFeedback = false;
      });
    } else {
      final totalQuestions = widget.lesson.questions.length;
      final stars = ((correctCount / totalQuestions) * 3).ceil();

      await widget.onComplete(
        stars: stars,
        correctAnswers: correctCount,
        totalQuestions: totalQuestions,
        wrongQuestions: wrongQuestions,
        correctQuestions: correctQuestions,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = currentQuestion;
    final options = question.options;
    final correctAnswer = question.correctAnswer;
    final isCorrect = selectedAnswer == correctAnswer;
    final progress =
        (currentQuestionIndex + 1) / widget.lesson.questions.length;
    final prompt = question.promptFor(widget.selectedLanguage, promptMode);

    return Column(
      children: [
        _LessonTopBar(
          progress: progress,
          currentIndex: currentQuestionIndex + 1,
          totalCount: widget.lesson.questions.length,
          onClose: widget.onClose,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.lesson.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PromptModeSelector(
                      selectedMode: promptMode,
                      selectedLanguage: widget.selectedLanguage,
                      onChanged: (mode) {
                        setState(() {
                          promptMode = mode;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TappableSentence(
                      text: prompt,
                      language: widget.selectedLanguage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (question.signDescription.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        question.signDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    if (question.videoUrl != null) ...[
                      SignVideoPlayer(videoUrl: question.videoUrl!),
                      const SizedBox(height: 28),
                    ] else if (question.type == 'image-to-text' &&
                        question.imageUrl != null) ...[
                      _QuestionImage(imageUrl: question.imageUrl!),
                      const SizedBox(height: 28),
                    ],

                    if (question.type == 'text-to-image' &&
                        question.optionImageUrls != null &&
                        question.optionImageUrls!.length == options.length) ...[
                      _buildImageOptions(
                        options: options,
                        imageUrls: question.optionImageUrls!,
                        correctAnswer: correctAnswer,
                        isCorrect: isCorrect,
                      ),
                    ] else ...[
                      _buildTextOptions(
                        options: options,
                        correctAnswer: correctAnswer,
                        isCorrect: isCorrect,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: showFeedback
              ? _FeedbackBar(
                  key: ValueKey(currentQuestionIndex),
                  isCorrect: isCorrect,
                  correctText: options[correctAnswer],
                  explanationText: question.explanationFor(
                    widget.selectedLanguage,
                  ),
                  isLastQuestion:
                      currentQuestionIndex ==
                      widget.lesson.questions.length - 1,
                  onNext: handleNext,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTextOptions({
    required List<String> options,
    required int correctAnswer,
    required bool isCorrect,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isWide ? 2.3 : 4.0,
          ),
          itemBuilder: (context, index) {
            final style = _answerStyle(
              index: index,
              correctAnswer: correctAnswer,
              isCorrect: isCorrect,
            );

            return _AnswerCard(
              text: options[index],
              backgroundColor: style.backgroundColor,
              borderColor: style.borderColor,
              textColor: style.textColor,
              trailingIcon: style.trailingIcon,
              trailingColor: style.trailingColor,
              onTap: showFeedback ? null : () => handleAnswerSelect(index),
            );
          },
        );
      },
    );
  }

  Widget _buildImageOptions({
    required List<String> options,
    required List<String> imageUrls,
    required int correctAnswer,
    required bool isCorrect,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isWide ? 1.15 : 1.35,
          ),
          itemBuilder: (context, index) {
            final style = _answerStyle(
              index: index,
              correctAnswer: correctAnswer,
              isCorrect: isCorrect,
            );

            return _ImageAnswerCard(
              label: options[index],
              imageUrl: imageUrls[index],
              backgroundColor: style.backgroundColor,
              borderColor: style.borderColor,
              textColor: style.textColor,
              trailingIcon: style.trailingIcon,
              trailingColor: style.trailingColor,
              onTap: showFeedback ? null : () => handleAnswerSelect(index),
            );
          },
        );
      },
    );
  }

  _AnswerStyle _answerStyle({
    required int index,
    required int correctAnswer,
    required bool isCorrect,
  }) {
    final isSelected = selectedAnswer == index;
    final isCorrectOption = index == correctAnswer;

    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE5E7EB);
    Color textColor = const Color(0xFF111827);
    IconData? trailingIcon;
    Color? trailingColor;

    if (showFeedback) {
      if (isSelected && isCorrect) {
        backgroundColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF22C55E);
        textColor = const Color(0xFF166534);
        trailingIcon = Icons.check_circle;
        trailingColor = const Color(0xFF16A34A);
      } else if (isSelected && !isCorrect) {
        backgroundColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFF991B1B);
        trailingIcon = Icons.cancel;
        trailingColor = const Color(0xFFDC2626);
      } else if (isCorrectOption) {
        backgroundColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF22C55E);
        textColor = const Color(0xFF166534);
        trailingIcon = Icons.check_circle;
        trailingColor = const Color(0xFF16A34A);
      } else {
        backgroundColor = const Color(0xFFF9FAFB);
        borderColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF9CA3AF);
      }
    }

    return _AnswerStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      textColor: textColor,
      trailingIcon: trailingIcon,
      trailingColor: trailingColor,
    );
  }
}

class _PromptModeSelector extends StatelessWidget {
  final QuestionPromptMode selectedMode;
  final AppLanguage selectedLanguage;
  final ValueChanged<QuestionPromptMode> onChanged;

  const _PromptModeSelector({
    required this.selectedMode,
    required this.selectedLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QuestionPromptMode>(
      segments: [
        const ButtonSegment(
          value: QuestionPromptMode.schoolJa,
          label: Text('学校日本語'),
          icon: Icon(Icons.school_rounded),
        ),
        const ButtonSegment(
          value: QuestionPromptMode.easyJa,
          label: Text('やさしい日本語'),
          icon: Icon(Icons.lightbulb_outline_rounded),
        ),
        ButtonSegment(
          value: QuestionPromptMode.native,
          label: Text(selectedLanguage.label),
          icon: const Icon(Icons.translate_rounded),
        ),
      ],
      selected: {selectedMode},
      onSelectionChanged: (values) => onChanged(values.first),
      showSelectedIcon: false,
    );
  }
}

class _AnswerStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;

  _AnswerStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.trailingIcon,
    required this.trailingColor,
  });
}

class _LessonTopBar extends StatelessWidget {
  final double progress;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onClose;

  const _LessonTopBar({
    required this.progress,
    required this.currentIndex,
    required this.totalCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        color: Colors.white,
      ),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currentIndex / $totalCount',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  final String imageUrl;

  const _QuestionImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                '画像を表示できません',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _AnswerCard({
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.trailingIcon,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: trailingColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageAnswerCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _ImageAnswerCard({
    required this.label,
    required this.imageUrl,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.trailingIcon,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Text(
                            '画像なし',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(trailingIcon, color: trailingColor, size: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String correctText;
  final String explanationText;
  final bool isLastQuestion;
  final Future<void> Function() onNext;

  const _FeedbackBar({
    super.key,
    required this.isCorrect,
    required this.correctText,
    required this.explanationText,
    required this.isLastQuestion,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFEF2F2);
    final borderColor = isCorrect
        ? const Color(0xFFBBF7D0)
        : const Color(0xFFFECACA);
    final titleColor = isCorrect
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);
    final buttonColor = isCorrect
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? '正解です！' : '不正解です',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCorrect
                            ? (explanationText.isEmpty
                                  ? 'その調子で進みましょう。'
                                  : explanationText)
                            : '正解は「$correctText」です。${explanationText.isEmpty ? '' : explanationText}',
                        style: TextStyle(fontSize: 15, color: titleColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onNext,
                  child: Text(
                    isLastQuestion ? '完了' : '次へ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
