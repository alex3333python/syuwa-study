import 'package:flutter/material.dart';

import '../models/answer_record.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../widgets/question_visual.dart';
import '../widgets/ruby_text.dart';
import '../widgets/sign_video_player.dart';
import '../widgets/writing_canvas.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Future<void> Function({
    required int stars,
    required int correctAnswers,
    required int totalQuestions,
    required List<Question> wrongQuestions,
    required List<Question> correctQuestions,
    required List<AnswerRecord> answerRecords,
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
  int currentStepIndex = 0;
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool showFeedback = false;
  bool showIndependentHint = false;
  bool showNoteOverlay = false;
  int correctCount = 0;
  final List<Question> wrongQuestions = [];
  final List<Question> correctQuestions = [];
  final List<AnswerRecord> answerRecords = [];
  QuestionPromptMode promptMode = QuestionPromptMode.schoolJa;

  bool get hasSteps => widget.lesson.steps.isNotEmpty;

  LessonStep? get currentStep =>
      hasSteps ? widget.lesson.steps[currentStepIndex] : null;

  List<Question> get currentQuestions =>
      hasSteps ? currentStep!.questions : widget.lesson.questions;

  Question get currentQuestion => currentQuestions[currentQuestionIndex];

  int get totalPracticeQuestions {
    if (!hasSteps) return widget.lesson.questions.length;
    return widget.lesson.steps.expand((step) => step.questions).length;
  }

  int get progressIndex =>
      hasSteps ? currentStepIndex + 1 : currentQuestionIndex + 1;

  int get progressTotal =>
      hasSteps ? widget.lesson.steps.length : widget.lesson.questions.length;

  void handleAnswerSelect(int answerIndex) {
    if (showFeedback) return;

    setState(() {
      selectedAnswer = answerIndex;
      showFeedback = true;

      if (answerIndex == currentQuestion.correctAnswer) {
        correctCount++;
        correctQuestions.add(currentQuestion);
        _updateCurrentAnswerRecord();
      } else {
        wrongQuestions.add(currentQuestion);
      }
    });
  }

  Future<void> handleNext() async {
    if (hasSteps && currentQuestions.isEmpty) {
      await _advanceStepOrComplete();
      return;
    }

    _updateCurrentAnswerRecord();

    if (currentQuestionIndex < currentQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        showIndependentHint = false;
        showFeedback = false;
        showNoteOverlay = false;
      });
      return;
    }

    if (hasSteps && currentStepIndex < widget.lesson.steps.length - 1) {
      setState(() {
        currentStepIndex++;
        currentQuestionIndex = 0;
        selectedAnswer = null;
        showIndependentHint = false;
        showFeedback = false;
        showNoteOverlay = false;
      });
      return;
    }

    await _completeLesson();
  }

  Future<void> _advanceStepOrComplete() async {
    if (hasSteps && currentStepIndex < widget.lesson.steps.length - 1) {
      setState(() {
        currentStepIndex++;
        currentQuestionIndex = 0;
        selectedAnswer = null;
        showIndependentHint = false;
        showFeedback = false;
        showNoteOverlay = false;
      });
      return;
    }

    await _completeLesson();
  }

  Future<void> _completeLesson() async {
    final totalQuestions = totalPracticeQuestions;
    final stars = totalQuestions == 0
        ? 3
        : ((correctCount / totalQuestions) * 3).ceil();

    await widget.onComplete(
      stars: stars,
      correctAnswers: correctCount,
      totalQuestions: totalQuestions,
      wrongQuestions: wrongQuestions,
      correctQuestions: correctQuestions,
      answerRecords: answerRecords,
    );
  }

  void _updateCurrentAnswerRecord() {
    final answer = selectedAnswer;
    if (answer == null) return;

    final isCorrect = answer == currentQuestion.correctAnswer;
    final record = AnswerRecord(
      question: currentQuestion,
      selectedAnswer: answer,
      isCorrect: isCorrect,
      mistakeReason: null,
    );
    final existingIndex = answerRecords.indexWhere(
      (record) => record.question.id == currentQuestion.id,
    );

    if (existingIndex == -1) {
      answerRecords.add(record);
    } else {
      answerRecords[existingIndex] = record;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasSteps && currentQuestions.isEmpty) {
      return _buildStepOnlyView();
    }

    final question = currentQuestion;
    final options = question.options;
    final correctAnswer = question.correctAnswer;
    final isCorrect = selectedAnswer == correctAnswer;
    final progress = progressIndex / progressTotal;
    final stepType = currentStep?.type;
    final isIndependent = stepType == LessonStepType.independentPractice;
    final promptModeForQuestion = isIndependent
        ? QuestionPromptMode.schoolJa
        : promptMode;
    final promptRuby = question.promptRubyFor(
      widget.selectedLanguage,
      promptModeForQuestion,
    );
    final optionRubies = question.resolvedChoicesRuby;
    return Stack(
      children: [
        Column(
          children: [
            _LessonTopBar(
              progress: progress,
              currentIndex: progressIndex,
              totalCount: progressTotal,
              onClose: widget.onClose,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                        if (hasSteps) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentStep!.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (!isIndependent) ...[
                          _PromptModeCards(
                            selectedMode: promptMode,
                            selectedLanguage: widget.selectedLanguage,
                            onChanged: (mode) {
                              setState(() {
                                promptMode = mode;
                              });
                            },
                          ),
                          const SizedBox(height: 22),
                        ] else ...[
                          _IndependentPracticeHeader(
                            showHint: showIndependentHint,
                            hintText: question.promptFor(
                              widget.selectedLanguage,
                              QuestionPromptMode.easyJa,
                            ),
                            onToggleHint: () {
                              setState(() {
                                showIndependentHint = !showIndependentHint;
                              });
                            },
                          ),
                          const SizedBox(height: 22),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: _NoteButton(
                            onPressed: () {
                              setState(() {
                                showNoteOverlay = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        RubyText(
                          text: promptRuby,
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
                        if (question.hasVisual) ...[
                          const SizedBox(height: 24),
                          QuestionVisual(question: question),
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
                            question.optionImageUrls!.length == options.length)
                          _buildImageOptions(
                            options: options,
                            imageUrls: question.optionImageUrls!,
                            optionRubies: optionRubies,
                            correctAnswer: correctAnswer,
                            isCorrect: isCorrect,
                          )
                        else
                          _buildTextOptions(
                            options: options,
                            optionRubies: optionRubies,
                            correctAnswer: correctAnswer,
                            isCorrect: isCorrect,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showFeedback)
          _ExplanationOverlay(
            isCorrect: isCorrect,
            question: question,
            correctAnswerText: question.resolvedCorrectAnswerTextRuby,
            explanationText: question.explanationRubyFor(
              widget.selectedLanguage,
            ),
            formulaExplanation: question.resolvedFormulaExplanationRuby,
            visualHint: question.visualHint.isNotEmpty
                ? question.visualHint
                : question.pictureDescription,
            languagePoint: question.resolvedLanguagePointRuby,
            isLastQuestion: !hasSteps
                ? currentQuestionIndex == widget.lesson.questions.length - 1
                : currentStepIndex == widget.lesson.steps.length - 1 &&
                      currentQuestionIndex == currentQuestions.length - 1,
            onNext: handleNext,
          ),
        if (showNoteOverlay)
          _NoteOverlay(
            key: ValueKey('note-${question.id}'),
            onClose: () {
              setState(() {
                showNoteOverlay = false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildStepOnlyView() {
    final step = currentStep!;
    final isSummary = step.type == LessonStepType.summary;
    final progress = progressIndex / progressTotal;
    final nativeTitle = widget.selectedLanguage == AppLanguage.japanese
        ? '母語'
        : widget.selectedLanguage.label;

    return Column(
      children: [
        _LessonTopBar(
          progress: progress,
          currentIndex: progressIndex,
          totalCount: progressTotal,
          onClose: widget.onClose,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
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
                    const SizedBox(height: 10),
                    Text(
                      isSummary ? '今日できたこと' : step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _StepExplanationCard(
                      icon: isSummary
                          ? Icons.flag_rounded
                          : Icons.school_rounded,
                      title: isSummary ? 'まとめ' : '学校日本語',
                      text: step.explanationFor(
                        widget.selectedLanguage,
                        QuestionPromptMode.schoolJa,
                      ),
                    ),
                    if (!isSummary) ...[
                      const SizedBox(height: 12),
                      _StepExplanationCard(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'やさしい日本語',
                        text: step.explanationFor(
                          widget.selectedLanguage,
                          QuestionPromptMode.easyJa,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StepExplanationCard(
                        icon: Icons.translate_rounded,
                        title: nativeTitle,
                        text: step.explanationFor(
                          widget.selectedLanguage,
                          QuestionPromptMode.native,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: handleNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  currentStepIndex == widget.lesson.steps.length - 1
                      ? '完了'
                      : '次へ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextOptions({
    required List<String> options,
    required List<String> optionRubies,
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
            childAspectRatio: isWide ? 1.95 : 3.15,
          ),
          itemBuilder: (context, index) {
            final style = _answerStyle(
              index: index,
              correctAnswer: correctAnswer,
              isCorrect: isCorrect,
            );

            return _AnswerCard(
              rubyText: optionRubies[index],
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
    required List<String> optionRubies,
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
              labelRuby: optionRubies[index],
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

class _PromptModeCards extends StatelessWidget {
  final QuestionPromptMode selectedMode;
  final AppLanguage selectedLanguage;
  final ValueChanged<QuestionPromptMode> onChanged;

  const _PromptModeCards({
    required this.selectedMode,
    required this.selectedLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '問題文の見かたをえらぶ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final buttons = [
              _PromptModeCard(
                mode: QuestionPromptMode.schoolJa,
                selectedMode: selectedMode,
                icon: Icons.school_rounded,
                title: '学校日本語',
                subtitle: '教科書に近い文',
                onTap: onChanged,
              ),
              _PromptModeCard(
                mode: QuestionPromptMode.easyJa,
                selectedMode: selectedMode,
                icon: Icons.lightbulb_outline_rounded,
                title: 'やさしい日本語',
                subtitle: '短い言葉で確認',
                onTap: onChanged,
              ),
              _PromptModeCard(
                mode: QuestionPromptMode.native,
                selectedMode: selectedMode,
                icon: Icons.translate_rounded,
                title: selectedLanguage.label,
                subtitle: '母語で確認',
                onTap: onChanged,
              ),
            ];

            if (isWide) {
              return Row(
                children: [
                  for (int i = 0; i < buttons.length; i++) ...[
                    Expanded(child: buttons[i]),
                    if (i != buttons.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            }

            return Column(
              children: [
                for (int i = 0; i < buttons.length; i++) ...[
                  buttons[i],
                  if (i != buttons.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IndependentPracticeHeader extends StatelessWidget {
  final bool showHint;
  final String hintText;
  final VoidCallback onToggleHint;

  const _IndependentPracticeHeader({
    required this.showHint,
    required this.hintText,
    required this.onToggleHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFFB45309)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '自分で解こう',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onToggleHint,
                icon: Icon(
                  showHint
                      ? Icons.visibility_off_rounded
                      : Icons.lightbulb_outline_rounded,
                ),
                label: Text(showHint ? 'ヒントを隠す' : 'ヒントを見る'),
              ),
            ],
          ),
          if (showHint) ...[
            const SizedBox(height: 10),
            Text(
              hintText,
              style: const TextStyle(
                color: Color(0xFF78350F),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepExplanationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _StepExplanationCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                RubyText(
                  text: text,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptModeCard extends StatelessWidget {
  final QuestionPromptMode mode;
  final QuestionPromptMode selectedMode;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<QuestionPromptMode> onTap;

  const _PromptModeCard({
    required this.mode,
    required this.selectedMode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = mode == selectedMode;
    final backgroundColor = selected ? const Color(0xFFEFF6FF) : Colors.white;
    final borderColor = selected
        ? const Color(0xFF2563EB)
        : const Color(0xFFE5E7EB);
    final iconColor = selected
        ? const Color(0xFF2563EB)
        : const Color(0xFF6B7280);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
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
  final String rubyText;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _AnswerCard({
    required this.rubyText,
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
                child: RubyText(
                  text: rubyText,
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
  final String labelRuby;
  final String imageUrl;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _ImageAnswerCard({
    required this.labelRuby,
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
                    child: RubyText(
                      text: labelRuby,
                      style: TextStyle(
                        fontSize: 15,
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

class _NoteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NoteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_note_rounded, size: 28),
      label: const Text('ノート'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _NoteOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const _NoteOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.02),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: WritingCanvas(
              height: MediaQuery.sizeOf(context).height * 0.68,
              title: 'ノート',
              showCloseButton: true,
              onClose: onClose,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationOverlay extends StatelessWidget {
  final bool isCorrect;
  final Question question;
  final String correctAnswerText;
  final String explanationText;
  final String formulaExplanation;
  final String visualHint;
  final String languagePoint;
  final bool isLastQuestion;
  final Future<void> Function() onNext;

  const _ExplanationOverlay({
    required this.isCorrect,
    required this.question,
    required this.correctAnswerText,
    required this.explanationText,
    required this.formulaExplanation,
    required this.visualHint,
    required this.languagePoint,
    required this.isLastQuestion,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.36),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 780,
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 36,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.lightbulb_circle_rounded,
                                    color: isCorrect
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFF59E0B),
                                    size: 46,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      isCorrect ? '正解です' : 'いっしょに見てみよう',
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _ExplanationSection(
                                icon: Icons.fact_check_rounded,
                                title: '正しい答え',
                                text: correctAnswerText,
                                accentColor: const Color(0xFF16A34A),
                              ),
                              if (question.hasVisual) ...[
                                const SizedBox(height: 12),
                                QuestionVisual(
                                  question: question,
                                  compact: true,
                                  showSolution: true,
                                ),
                              ] else if (visualHint.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _ExplanationSection(
                                  icon: Icons.grid_view_rounded,
                                  title: '図や補助説明',
                                  text: visualHint,
                                  accentColor: const Color(0xFF0891B2),
                                ),
                              ],
                              if (explanationText.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _ExplanationSection(
                                  icon: Icons.tips_and_updates_rounded,
                                  title: '解き方の説明',
                                  text: explanationText,
                                  accentColor: const Color(0xFF2563EB),
                                ),
                              ],
                              if (formulaExplanation.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _ExplanationSection(
                                  icon: Icons.functions_rounded,
                                  title: '式の説明',
                                  text: formulaExplanation,
                                  accentColor: const Color(0xFF7C3AED),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _ExplanationSection(
                                icon: Icons.menu_book_rounded,
                                title: '日本語のポイント',
                                text: languagePoint,
                                accentColor: const Color(0xFFF97316),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            top: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: SizedBox(
                          height: 64,
                          child: FilledButton.icon(
                            onPressed: onNext,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(isLastQuestion ? '完了' : '次へ'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color accentColor;

  const _ExplanationSection({
    required this.icon,
    required this.title,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
