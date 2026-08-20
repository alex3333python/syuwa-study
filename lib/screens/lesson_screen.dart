import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/audio_cues.dart';
import '../data/equal_share_language_support.dart';
import '../data/learning_language_support.dart';
import '../data/native_text.dart';
import '../models/answer_record.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../theme/app_fonts.dart';
import '../widgets/lesson_language_scope.dart';
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

  List<LessonStep> get visibleSteps => widget.lesson.steps
      .where((step) => step.type != LessonStepType.summary)
      .toList();

  bool get hasSteps => visibleSteps.isNotEmpty;

  LessonStep? get currentStep =>
      hasSteps ? visibleSteps[currentStepIndex] : null;

  List<Question> get currentQuestions =>
      hasSteps ? currentStep!.questions : widget.lesson.questions;

  Question get currentQuestion => currentQuestions[currentQuestionIndex];

  int get totalPracticeQuestions {
    if (!hasSteps) return widget.lesson.questions.length;
    return visibleSteps.expand((step) => step.questions).length;
  }

  int get progressIndex =>
      hasSteps ? currentStepIndex + 1 : currentQuestionIndex + 1;

  int get progressTotal =>
      hasSteps ? visibleSteps.length : widget.lesson.questions.length;

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

    if (hasSteps && currentStepIndex < visibleSteps.length - 1) {
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
    if (hasSteps && currentStepIndex < visibleSteps.length - 1) {
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
    final isJapaneseOnlyChallenge =
        currentStep?.title == '日本語だけで挑戦' ||
        currentStep?.title == 'たしかめ問題' ||
        widget.lesson.title == 'たしかめ問題' ||
        (currentStep?.id.contains('japanese') ?? false);
    final supportsLearningLanguage =
        !isJapaneseOnlyChallenge &&
        (stepType == LessonStepType.learn ||
            stepType == LessonStepType.guidedPractice ||
            stepType == LessonStepType.independentPractice);
    final questionLanguage = isJapaneseOnlyChallenge
        ? AppLanguage.japanese
        : widget.selectedLanguage;
    final explanationLanguage = question.unit == 'time'
        ? widget.selectedLanguage
        : questionLanguage;
    final promptModeForQuestion = isIndependent
        ? QuestionPromptMode.schoolJa
        : promptMode == QuestionPromptMode.easyJa
        ? QuestionPromptMode.schoolJa
        : promptMode;
    final promptRuby = question.promptRubyFor(
      widget.selectedLanguage,
      promptModeForQuestion,
    );
    final optionRubies = question.resolvedChoicesRuby;
    return LessonLanguageScope(
      language: widget.selectedLanguage,
      child: Stack(
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
                        ] else if (!isJapaneseOnlyChallenge) ...[
                          _IndependentPracticeHeader(
                            showHint: showIndependentHint,
                            hintText: _independentPracticeHint(
                              question,
                              widget.selectedLanguage,
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
                          vocabularyEntries: supportsLearningLanguage
                              ? mergeLearningVocabulary(
                                  question.vocabularyEntries,
                                )
                              : const <VocabularyEntry>[],
                          language: widget.selectedLanguage,
                          enableLearningSupport: supportsLearningLanguage,
                          learningSupportMode: supportsLearningLanguage
                              ? LearningSupportMode.rubyAndDictionary
                              : LearningSupportMode.off,
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
                        if (question.hasVisual &&
                            (!isIndependent ||
                                question.diagramType == 'eraser_ruler' ||
                                question.diagramType == 'weight_scale') &&
                            question.diagramType != 'time_line') ...[
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
                        if (question.choiceDiagramData.length == options.length)
                          _buildDiagramOptions(
                            options: options,
                            optionRubies: optionRubies,
                            diagrams: question.choiceDiagramData,
                            correctAnswer: correctAnswer,
                            isCorrect: isCorrect,
                          )
                        else if (question.type == 'text-to-image' &&
                            question.optionImageUrls != null &&
                            question.optionImageUrls!.length == options.length)
                          _buildImageOptions(
                            options: options,
                            imageUrls: question.optionImageUrls!,
                            optionRubies: optionRubies,
                            correctAnswer: correctAnswer,
                            isCorrect: isCorrect,
                            vocabularyEntries: question.vocabularyEntries,
                          )
                        else
                          _buildTextOptions(
                            options: options,
                            optionRubies: optionRubies,
                            correctAnswer: correctAnswer,
                            isCorrect: isCorrect,
                            vocabularyEntries: question.vocabularyEntries,
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
            questionLanguage: questionLanguage,
            explanationLanguage: explanationLanguage,
            correctAnswerText: question.resolvedCorrectAnswerTextRuby,
            explanationText: question.explanationRubyFor(questionLanguage),
            formulaExplanation: widget.lesson.id == 7
                ? ''
                : question.resolvedFormulaExplanationRuby,
            visualHint: question.visualHint.isNotEmpty
                ? question.visualHint
                : question.pictureDescription,
            languagePoint: widget.lesson.id == 7
                ? ''
                : question.resolvedLanguagePointRuby,
            isLastQuestion: !hasSteps
                ? currentQuestionIndex == widget.lesson.questions.length - 1
                : currentStepIndex == visibleSteps.length - 1 &&
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
      ),
    );
  }

  Widget _buildStepOnlyView() {
    final step = currentStep!;
    final progress = progressIndex / progressTotal;
    final nativeTitle = widget.selectedLanguage == AppLanguage.japanese
        ? '母語'
        : widget.selectedLanguage.label;
    final richLearnCard = _buildRichLearnCard(step, widget.selectedLanguage);
    final actionLabel =
        step.id == 'division-equal-share-words' ||
            step.id == 'division-measure-words'
        ? 'もんだいをとく'
        : currentStepIndex == visibleSteps.length - 1
        ? '完了'
        : '次へ';

    return LessonLanguageScope(
      language: widget.selectedLanguage,
      child: Column(
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
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (richLearnCard != null) ...[
                      richLearnCard,
                      const SizedBox(height: 16),
                    ] else ...[
                      _StepExplanationCard(
                        icon: Icons.school_rounded,
                        title: '学校日本語',
                        text: step.explanationFor(
                          widget.selectedLanguage,
                          QuestionPromptMode.schoolJa,
                        ),
                      ),
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
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: AppFonts.interface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildTextOptions({
    required List<String> options,
    required List<String> optionRubies,
    required int correctAnswer,
    required bool isCorrect,
    required List<VocabularyEntry> vocabularyEntries,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final useCompactLayout = optionRubies.every(_choiceTextLooksCompact);

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
              useCompactLayout: useCompactLayout,
              vocabularyEntries: vocabularyEntries,
              language: widget.selectedLanguage,
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
    required List<VocabularyEntry> vocabularyEntries,
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
              vocabularyEntries: vocabularyEntries,
              language: widget.selectedLanguage,
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

  Widget _buildDiagramOptions({
    required List<String> options,
    required List<String> optionRubies,
    required List<Map<String, String>> diagrams,
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
            childAspectRatio: isWide ? 1.35 : 1.55,
          ),
          itemBuilder: (context, index) {
            final style = _answerStyle(
              index: index,
              correctAnswer: correctAnswer,
              isCorrect: isCorrect,
            );

            return _DiagramAnswerCard(
              diagram: diagrams[index],
              itemKind: _choiceDiagramItemKind(currentQuestion),
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

  String _choiceDiagramItemKind(Question question) {
    final text = [
      question.promptSchoolJa,
      question.promptEasyJa,
      question.visualHint,
      question.pictureDescription,
    ].join(' ');
    if (text.contains('いちご')) return 'strawberry';
    if (text.contains('りんご')) return 'apple';
    if (text.contains('あめ')) return 'candy';
    if (text.contains('クッキー')) return 'cookie';
    if (text.contains('シール')) return 'sticker';
    if (text.contains('カード')) return 'card';
    if (text.contains('ビー玉')) return 'marble';
    if (text.contains('えんぴつ')) return 'pencil';
    return 'sticker';
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
    final effectiveSelectedMode = selectedMode == QuestionPromptMode.easyJa
        ? QuestionPromptMode.schoolJa
        : selectedMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final buttons = [
              _PromptModeCard(
                mode: QuestionPromptMode.schoolJa,
                selectedMode: effectiveSelectedMode,
                icon: Icons.school_rounded,
                title: '日本語',
                onTap: onChanged,
              ),
              _PromptModeCard(
                mode: QuestionPromptMode.native,
                selectedMode: effectiveSelectedMode,
                icon: Icons.translate_rounded,
                title: selectedLanguage.label,
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
              Tooltip(
                message: showHint ? 'ヒントを隠す' : 'ヒントを見る',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onToggleHint,
                    icon: Icon(
                      showHint
                          ? Icons.visibility_off_rounded
                          : Icons.lightbulb_outline_rounded,
                    ),
                    color: const Color(0xFF6D4C9B),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.padded,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
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

String _independentPracticeHint(Question question, AppLanguage language) {
  final timeHint = _timeIndependentPracticeHint(question);
  if (timeHint.isNotEmpty) return timeHint;
  final lengthHint = _lengthIndependentPracticeHint(question);
  if (lengthHint.isNotEmpty) return lengthHint;

  final text =
      '${question.promptSchoolJa} ${question.promptEasyJa} '
      '${question.vocabulary.join(' ')}';

  final perPersonMatch = RegExp(
    r'1人に([0-9０-９]+(?:こ|本|まい|枚)?)ずつ',
  ).firstMatch(text);
  if (perPersonMatch != null) {
    final amount = perPersonMatch.group(1)!;
    if (language != AppLanguage.japanese) {
      final native = switch (language) {
        AppLanguage.portuguese => '$amount para cada pessoa',
        AppLanguage.tagalog => '$amount para sa bawat tao',
        AppLanguage.vietnamese => '$amount cho mỗi người',
        AppLanguage.japanese => '',
      };
      if (native.isNotEmpty) {
        return '「1人に$amountずつ」は、${language.label}で $native です。';
      }
    }
    return '「1人に$amountずつ」は、1人がもらう数が$amountという意味です。';
  }

  for (final entry in question.vocabularyEntries) {
    if (entry.term.isEmpty || !text.contains(entry.term)) continue;
    final native = entry.translations[language];
    if (language != AppLanguage.japanese &&
        native != null &&
        native.trim().isNotEmpty) {
      return '「${entry.term}」は、${language.label}で $native です。';
    }
    return '「${entry.term}」は、${entry.simpleJapanese}';
  }

  for (final support in _independentHintSupports) {
    if (!support.matches(text)) continue;
    final native = support.translations[language];
    if (language != AppLanguage.japanese &&
        native != null &&
        native.trim().isNotEmpty) {
      return '「${support.term}」は、${language.label}で $native です。';
    }
    return '「${support.term}」は、${support.simpleJapanese}';
  }

  return '問題文の大事なことばを見て、何を聞かれているかをたしかめましょう。';
}

String _timeIndependentPracticeHint(Question question) {
  if (question.unit != 'time') return '';

  return switch (question.type) {
    'across_hour' => 'まず、次のちょうどの時こくまで何分あるか見てみましょう。そこまで進めたら、残りの分をもう一度進めます。',
    'noon' => '12時をまたぐと、午前から午後に変わります。まず正午まで何分あるかを見てみましょう。',
    'minutes_after' => '「何分後」は時計を進めます。近いちょうどの時こくまで進めてから、残りの分を考えましょう。',
    'minutes_before' ||
    'start_time' => '「前」や「何時に出た」は時計を戻して考えます。終わりの時こくから、かかった時間だけ戻しましょう。',
    'compare_time' => '単位がちがうときは、同じ単位にそろえて比べます。1分は60秒です。',
    'seconds_life' => '50m走はとても短い時間です。「時・分・秒」の中で、短い時間を表しやすい単位を考えましょう。',
    'minutes_seconds' => '分と秒がまざっているときは、分を秒に直してから考えます。1分は60秒です。',
    _ => '',
  };
}

String _lengthIndependentPracticeHint(Question question) {
  if (question.unit != 'length') return '';

  return switch (question.type) {
    'tool_choice' =>
      'はかるものの大きさや形を見ましょう。短くてまっすぐならものさし、長いものや曲がったものならまきじゃくが使いやすいです。',
    'read_measure' => '目もりの数字を見ましょう。はじめは0に合わせて、先がどの数字を指しているかを読みます。',
    'km_relation' => '1000mと1kmは同じ長さです。mの数が大きくなったら、kmで表せないか考えましょう。',
    'km_to_m' || 'm_to_km' => '1kmは1000mです。kmをmに直すと、たし算しやすくなります。',
    'compare_length' => '単位がちがうときは、mにそろえて比べましょう。1kmは1000mです。',
    'route_addition' => '道のりは、通った道をつなげて考えます。区間の長さを順番に合わせましょう。',
    _ => '',
  };
}

class _IndependentHintSupport {
  final String term;
  final List<String> aliases;
  final String simpleJapanese;
  final Map<AppLanguage, String> translations;

  const _IndependentHintSupport({
    required this.term,
    this.aliases = const [],
    required this.simpleJapanese,
    required this.translations,
  });

  bool matches(String text) {
    return text.contains(term) || aliases.any(text.contains);
  }
}

const _independentHintSupports = [
  _IndependentHintSupport(
    term: '同じ数ずつ',
    simpleJapanese: 'みんなが同じ数になるように分けることです。',
    translations: {
      AppLanguage.portuguese: 'a mesma quantidade para cada pessoa',
      AppLanguage.tagalog: 'pare-parehong dami para sa bawat tao',
      AppLanguage.vietnamese: 'cùng một số lượng cho mỗi người',
    },
  ),
  _IndependentHintSupport(
    term: '分ける',
    aliases: ['分けます', '分けた', '分けられます', '分けられる'],
    simpleJapanese: 'ものをいくつかのグループにすることです。',
    translations: {
      AppLanguage.portuguese: 'dividir / separar em grupos',
      AppLanguage.tagalog: 'hatiin sa mga grupo',
      AppLanguage.vietnamese: 'chia thành các nhóm',
    },
  ),
  _IndependentHintSupport(
    term: '1人分',
    aliases: ['一人分'],
    simpleJapanese: '1人がもらう数です。',
    translations: {
      AppLanguage.portuguese: 'quantidade para uma pessoa',
      AppLanguage.tagalog: 'bahagi para sa isang tao',
      AppLanguage.vietnamese: 'phần cho một người',
    },
  ),
  _IndependentHintSupport(
    term: '全部の数',
    aliases: ['ぜんぶの数'],
    simpleJapanese: 'はじめにあるものを全部数えた数です。',
    translations: {
      AppLanguage.portuguese: 'número total',
      AppLanguage.tagalog: 'kabuuang bilang',
      AppLanguage.vietnamese: 'tổng số',
    },
  ),
  _IndependentHintSupport(
    term: '分ける人数',
    simpleJapanese: '何人に分けるかという数です。',
    translations: {
      AppLanguage.portuguese: 'número de pessoas',
      AppLanguage.tagalog: 'bilang ng mga tao',
      AppLanguage.vietnamese: 'số người',
    },
  ),
  _IndependentHintSupport(
    term: '何人',
    simpleJapanese: '人の数を聞く言い方です。',
    translations: {
      AppLanguage.portuguese: 'quantas pessoas',
      AppLanguage.tagalog: 'ilang tao',
      AppLanguage.vietnamese: 'bao nhiêu người',
    },
  ),
  _IndependentHintSupport(
    term: '式',
    simpleJapanese: '計算を、数字や記号で書いたものです。',
    translations: {
      AppLanguage.portuguese: 'conta / expressão matemática',
      AppLanguage.tagalog: 'pahayag sa matematika',
      AppLanguage.vietnamese: 'phép tính / biểu thức',
    },
  ),
  _IndependentHintSupport(
    term: 'あまり',
    simpleJapanese: '同じ数ずつ分けたあとに残る数です。',
    translations: {
      AppLanguage.portuguese: 'resto / sobra',
      AppLanguage.tagalog: 'sobra / natira',
      AppLanguage.vietnamese: 'số dư',
    },
  ),
];

Widget? _buildRichLearnCard(LessonStep step, AppLanguage selectedLanguage) {
  switch (step.id) {
    case 'division-equal-share-learn':
      return _EqualShareInteractiveLearn(
        selectedLanguage: selectedLanguage,
        nativeText: step.explanationFor(
          selectedLanguage,
          QuestionPromptMode.native,
        ),
      );
    case 'division-equal-share-words':
      return _EqualShareWordsCard(selectedLanguage: selectedLanguage);
    case 'division-measure-learn':
      return _EqualShareInteractiveLearn(
        selectedLanguage: selectedLanguage,
        nativeText: step.explanationFor(
          selectedLanguage,
          QuestionPromptMode.native,
        ),
        title: '何人に分けられるかな',
        problemLines: measureDivisionProblemLines,
        instructionLine: measureDivisionInstruction,
        resultLines: measureDivisionResultLines,
        equationReading: measureDivisionEquationReading,
        equationSupports: measureDivisionEquationSupports,
        vocabularyEntries: measureDivisionVocabularyEntries,
        storyOrder: const [0, 0, 1, 1, 2, 2],
        successMessage: '3人に分けられたね！',
        retryMessage: '2こずつ分けられているかな？ お皿ごとの数を見てみよう。',
        storyMessage: '1人に2こずつ置いていきます。',
        storyCompleteMessage: '3人に分けられました。',
      );
    case 'division-measure-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: measureDivisionLessonVocabulary,
      );
    case 'division-multiplication-link-learn':
      return _MultiplicationDivisionLearn(selectedLanguage: selectedLanguage);
    case 'division-multiplication-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: zeroOneDivisionLessonVocabulary,
      );
    case 'division-zero-one-learn':
      return _ZeroOneDivisionLearn(selectedLanguage: selectedLanguage);
    case 'division-remainder-basic-learn':
      return _RemainderDivisionLearn(selectedLanguage: selectedLanguage);
    case 'division-remainder-basic-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: remainderBasicLessonVocabulary,
      );
    case 'division-remainder-context-learn':
      return _RemainderContextLearn(selectedLanguage: selectedLanguage);
    case 'division-remainder-context-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: remainderContextLessonVocabulary,
      );
    case 'time-main-learn':
      return _TimeMainLearn(selectedLanguage: selectedLanguage);
    case 'time-main-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: timeMainLessonVocabulary,
      );
    case 'time-short-learn':
      return _ShortTimeLearn(selectedLanguage: selectedLanguage);
    case 'time-short-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: shortTimeLessonVocabulary,
      );
    case 'length-measure-learn':
      return _LengthMeasureLearn(selectedLanguage: selectedLanguage);
    case 'length-measure-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: lengthMeasureLessonVocabulary,
      );
    case 'length-km-learn':
      return _KilometerLearn(selectedLanguage: selectedLanguage);
    case 'length-km-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: kilometerLessonVocabulary,
        vocabularyCardHeight: 214,
      );
    case 'weight-gram-kg-learn':
      return _WeightGramKgLearn(selectedLanguage: selectedLanguage);
    case 'weight-gram-kg-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: weightGramKgLessonVocabulary,
      );
    case 'weight-ton-learn':
      return _WeightTonLearn(selectedLanguage: selectedLanguage);
    case 'weight-ton-words':
      return _EqualShareWordsCard(
        selectedLanguage: selectedLanguage,
        vocabularyItems: weightTonLessonVocabulary,
      );
  }
  return null;
}

const _timeVocabularyEntries = [
  VocabularyEntry(
    term: '時こく',
    reading: 'じこく',
    simpleJapanese: '時計がさしている、ある1つの時です。',
    translations: {AppLanguage.portuguese: 'horário',
      AppLanguage.tagalog: 'oras / oras ng orasan',
      AppLanguage.vietnamese: 'thời điểm',},
    exampleSentence: '8時10分は時こくです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '時間',
    reading: 'じかん',
    simpleJapanese: 'ある時こくから、別の時こくまでの長さです。',
    translations: {AppLanguage.portuguese: 'tempo / duração',
      AppLanguage.tagalog: 'oras / tagal',
      AppLanguage.vietnamese: 'thời gian / khoảng thời gian',},
    exampleSentence: '25分は時間です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '前',
    reading: 'まえ',
    simpleJapanese: '時計を戻して考えることばです。',
    translations: {AppLanguage.portuguese: 'antes',
      AppLanguage.tagalog: 'bago',
      AppLanguage.vietnamese: 'trước',},
    exampleSentence: '25分前を考えます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '後',
    reading: 'あと / ご',
    simpleJapanese: '時計を進めて考えることばです。',
    translations: {AppLanguage.portuguese: 'depois',
      AppLanguage.tagalog: 'pagkatapos',
      AppLanguage.vietnamese: 'sau',},
    exampleSentence: '20分後を考えます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '出発',
    reading: 'しゅっぱつ',
    simpleJapanese: 'ある場所を出ることです。',
    translations: {AppLanguage.portuguese: 'partida',
      AppLanguage.tagalog: 'alis',
      AppLanguage.vietnamese: 'xuất phát',},
    exampleSentence: '7時45分に出発します。',
    category: 'school_language',
  ),
  VocabularyEntry(
    term: '到着',
    reading: 'とうちゃく',
    simpleJapanese: '行き先につくことです。',
    translations: {AppLanguage.portuguese: 'chegada',
      AppLanguage.tagalog: 'dating',
      AppLanguage.vietnamese: 'đến nơi',},
    exampleSentence: '8時10分に到着します。',
    category: 'school_language',
  ),
  VocabularyEntry(
    term: '午前',
    reading: 'ごぜん',
    simpleJapanese: '夜中の12時から、正午までの時こくにつける言葉です。',
    translations: {AppLanguage.portuguese: 'da manhã / a.m.',
      AppLanguage.tagalog: 'umaga / a.m.',
      AppLanguage.vietnamese: 'buổi sáng / a.m.',},
    exampleSentence: '午前7時40分に出発します。',
    category: 'time_language',
  ),
  VocabularyEntry(
    term: '午後',
    reading: 'ごご',
    simpleJapanese: '正午をすぎたあとの時こくにつける言葉です。',
    translations: {AppLanguage.portuguese: 'da tarde / p.m.',
      AppLanguage.tagalog: 'hapon / p.m.',
      AppLanguage.vietnamese: 'buổi chiều / p.m.',},
    exampleSentence: '午後3時40分に始まります。',
    category: 'time_language',
  ),
  VocabularyEntry(
    term: '秒',
    reading: 'びょう',
    simpleJapanese: '分より短い時間の単位です。',
    translations: {AppLanguage.portuguese: 'segundo',
      AppLanguage.tagalog: 'segundo',
      AppLanguage.vietnamese: 'giây',},
    exampleSentence: '1分は60秒です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '秒針',
    reading: 'びょうしん',
    simpleJapanese: '秒を表す時計の針です。',
    translations: {AppLanguage.portuguese: 'ponteiro dos segundos',
      AppLanguage.tagalog: 'segundong kamay ng orasan',
      AppLanguage.vietnamese: 'kim giây',},
    exampleSentence: '秒針が1周します。',
    category: 'math_language',
  ),
];

class _TimeMainLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _TimeMainLearn({required this.selectedLanguage});

  @override
  State<_TimeMainLearn> createState() => _TimeMainLearnState();
}

class _TimeMainLearnState extends State<_TimeMainLearn> {
  int _page = 0;
  bool _showNative = false;
  bool _showGuideNative = false;
  int _minuteOffset = 0;

  static const _lastPage = 1;

  void _previous() {
    if (_page == 0) return;
    setState(() {
      _page--;
      _minuteOffset = 0;
      _showGuideNative = false;
    });
  }

  void _next() {
    if (_page == _lastPage) return;
    setState(() {
      _page++;
      _minuteOffset = 0;
      _showGuideNative = false;
    });
  }

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: '時こくと時間',
      text: _currentPage.problem.japanese,
    );
  }

  _TimeLearnPage get _currentPage {
    return switch (_page) {
      0 => const _TimeLearnPage(
        title: '学校につく時こくを見つけよう',
        problem: SupportLine(
          japanese: '午前7時40分に家を出発してから、学校に着くまでに30分かかりました。学校に着いた時こくは何時何分ですか。',
          ruby:
              '{午前|ごぜん}7{時|じ}40{分|ぷん}に{家|いえ}を{出発|しゅっぱつ}してから、{学校|がっこう}に{着|つ}くまでに30{分|ぷん}かかりました。{学校|がっこう}に{着|つ}いた{時|じ}こくは{何時|なんじ}{何分|なんぷん}ですか。',
          native: {
            AppLanguage.portuguese:
                'Saiu de casa às 7:40 da manhã e levou 30 minutos para chegar à escola. A que horas chegou?',
            AppLanguage.tagalog:
                'Umalis siya sa bahay nang 7:40 ng umaga at 30 minuto ang biyahe papuntang paaralan. Anong oras siya dumating?',
            AppLanguage.vietnamese:
                'Rời nhà lúc 7:40 sáng và mất 30 phút để đến trường. Đến lúc mấy giờ?',
          },
        ),
        guide: SupportLine(
          japanese: '時計を30分動かしてみよう。',
          ruby: '{時計|とけい}を30{分|ぷん}{動|うご}かしてみよう。',
          native: {
            AppLanguage.portuguese: 'Mova o relógio 30 minutos.',
            AppLanguage.tagalog: 'Igala ang orasan ng 30 minuto.',
            AppLanguage.vietnamese: 'Hãy xoay đồng hồ thêm 30 phút.',
          }
        ),
        scenario: _ClockScenario(
          hour: 7,
          minute: 40,
          targetOffset: 30,
          completionMessage: '学校に着いたよ。',
        ),
        answer: '午前8時10分',
        explanation: 'かかった時間は30分だから、8時まで20分かかり、8時から10分かかる。だから、午前8時10分です。',
        splitLabels: ['20分', '10分'],
        splitStarts: [40, 0],
        splitMinutes: [20, 10],
        timelineLabels: ['午前7:40', '8:00', '午前8:10'],
      ),
      _ => const _TimeLearnPage(
        title: '映画の時間を見つけよう',
        problem: SupportLine(
          japanese: '午後3時40分に映画が始まって、午後4時50分に映画が終わりました。映画は何時間何分ありましたか。',
          ruby:
              '{午後|ごご}3{時|じ}40{分|ぷん}に{映画|えいが}が{始|はじ}まって、{午後|ごご}4{時|じ}50{分|ぷん}に{映画|えいが}が{終|お}わりました。{映画|えいが}は{何時間|なんじかん}{何分|なんぷん}ありましたか。',
          native: {
            AppLanguage.portuguese:
                'O filme começou às 3:40 da tarde e terminou às 4:50 da tarde. Quanto tempo durou?',
            AppLanguage.tagalog:
                'Nagsimula ang pelikula nang 3:40 ng hapon at natapos nang 4:50 ng hapon. Gaano katagal?',
            AppLanguage.vietnamese:
                'Phim bắt đầu lúc 3:40 chiều và kết thúc lúc 4:50 chiều. Kéo dài bao lâu?',
          },
        ),
        guide: SupportLine(
          japanese: '午後4時50分まで時計を動かしてみよう。',
          ruby: '{午後|ごご}4{時|じ}50{分|ぷん}まで{時計|とけい}を{動|うご}かしてみよう。',
          native: {
            AppLanguage.portuguese: 'Mova o relógio até 4:50 da tarde.',
            AppLanguage.tagalog: 'Igala ang orasan hanggang 4:50 ng hapon.',
            AppLanguage.vietnamese: 'Hãy xoay đồng hồ đến 4:50 chiều.',
          }
        ),
        scenario: _ClockScenario(
          hour: 15,
          minute: 40,
          targetOffset: 70,
          completionMessage: '映画が終わったよ。',
        ),
        answer: '1時間10分',
        explanation: '3時40分から4時まで20分、4時から4時50分まで50分。20+50=70分。70分は1時間10分です。',
        splitLabels: ['20分', '50分'],
        splitStarts: [40, 0],
        splitMinutes: [20, 50],
        timelineLabels: ['午後3:40', '4:00', '午後4:50'],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final page = _currentPage;
    final scenario = page.scenario;
    final minOffset = math.min(0, scenario.targetOffset);
    final maxOffset = math.max(0, scenario.targetOffset);
    final clampedOffset = _minuteOffset.clamp(minOffset, maxOffset).toInt();
    final reached = clampedOffset == scenario.targetOffset;

    return _RemainderLearnShell(
      icon: Icons.schedule_rounded,
      title: page.title,
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () {
        setState(() {
          final next = !_showNative;
          _showNative = next;
          _showGuideNative = next;
        });
      },
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: _previous,
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SupportedTextLines(
            lines: [page.problem],
            language: widget.selectedLanguage,
            showNative: _showNative,
            vocabularyEntries: _timeVocabularyEntries,
            enableLearningSupport: true,
          ),
          const SizedBox(height: 12),
          _SupportedInstruction(
            line: page.guide,
            language: widget.selectedLanguage,
            showNative: _showGuideNative,
            onToggleNative: () {
              setState(() => _showGuideNative = !_showGuideNative);
            },
            vocabularyEntries: _timeVocabularyEntries,
          ),
          const SizedBox(height: 18),
          _ClockActivityPanel(
            scenario: scenario,
            offset: clampedOffset,
            locked: reached,
            onChangeOffset: (delta) {
              setState(() {
                _minuteOffset = (_minuteOffset + delta)
                    .clamp(minOffset, maxOffset)
                    .toInt();
              });
            },
          ),
          if (reached) ...[
            const SizedBox(height: 16),
            _TimeResultBox(
              page: page,
              selectedLanguage: widget.selectedLanguage,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeLearnPage {
  final String title;
  final SupportLine problem;
  final SupportLine guide;
  final _ClockScenario scenario;
  final String answer;
  final String explanation;
  final List<String> splitLabels;
  final List<int> splitStarts;
  final List<int> splitMinutes;
  final List<String> timelineLabels;

  const _TimeLearnPage({
    required this.title,
    required this.problem,
    required this.guide,
    required this.scenario,
    required this.answer,
    required this.explanation,
    required this.splitLabels,
    required this.splitStarts,
    required this.splitMinutes,
    required this.timelineLabels,
  });
}

class _ShortTimeLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _ShortTimeLearn({required this.selectedLanguage});

  @override
  State<_ShortTimeLearn> createState() => _ShortTimeLearnState();
}

class _ShortTimeLearnState extends State<_ShortTimeLearn> {
  int _page = 0;
  bool _showNative = false;

  static const _lastPage = 1;

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: '短い時間',
      text: _pageLines.first.japanese,
    );
  }

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: '1分より短い時間の単位に、秒があります。',
          ruby: '1{分|ぷん}より{短|みじか}い{時間|じかん}の{単位|たんい}に、{秒|びょう}があります。',
          native: {
            AppLanguage.portuguese:
                'O segundo é uma unidade de tempo menor que 1 minuto.',
            AppLanguage.tagalog:
                'Ang segundo ay yunit ng oras na mas maikli kaysa 1 minuto.',
            AppLanguage.vietnamese:
                'Giây là đơn vị thời gian ngắn hơn 1 phút.',
          },
        ),
      ],
      _ => const [
        SupportLine(
          japanese: 'ストップウォッチの01:20は、1分20秒を表しています。',
          ruby: 'ストップウォッチの01:20は、1{分|ぷん}20{秒|びょう}を{表|あらわ}しています。',
          native: {
            AppLanguage.portuguese:
                'No cronômetro, 01:20 mostra 1 minuto e 20 segundos.',
            AppLanguage.tagalog:
                'Sa stopwatch, ang 01:20 ay 1 minuto at 20 segundo.',
            AppLanguage.vietnamese:
                'Trên đồng hồ bấm giờ, 01:20 là 1 phút 20 giây.',
          },
        ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return _RemainderLearnShell(
      icon: Icons.timer_rounded,
      title: '短い時間を感じよう',
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () {
        setState(() {
          _showNative = !_showNative;
        });
      },
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: () {
        if (_page == 0) return;
        setState(() {
          _page--;
        });
      },
      onNext: () {
        if (_page == _lastPage) return;
        setState(() {
          _page++;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SupportedTextLines(
            lines: _pageLines,
            language: widget.selectedLanguage,
            showNative: _showNative,
            vocabularyEntries: _timeVocabularyEntries,
            enableLearningSupport: true,
          ),
          const SizedBox(height: 20),
          switch (_page) {
            0 => _SecondHandPanel(selectedLanguage: widget.selectedLanguage),
            _ => _MinuteSecondPanel(selectedLanguage: widget.selectedLanguage),
          },
        ],
      ),
    );
  }
}

class _ClockScenario {
  final int hour;
  final int minute;
  final int targetOffset;
  final String completionMessage;

  const _ClockScenario({
    required this.hour,
    required this.minute,
    required this.targetOffset,
    this.completionMessage = 'ここまで進めたね。',
  });
}

class _SupportedInstruction extends StatelessWidget {
  final SupportLine line;
  final AppLanguage language;
  final bool showNative;
  final VoidCallback onToggleNative;
  final List<VocabularyEntry> vocabularyEntries;

  const _SupportedInstruction({
    required this.line,
    required this.language,
    required this.showNative,
    required this.onToggleNative,
    this.vocabularyEntries = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: _SupportedTextLines(
                lines: [line],
                language: language,
                showNative: showNative,
                vocabularyEntries: vocabularyEntries,
                learningSupportMode: LearningSupportMode.rubyAndDictionary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _IconSupportActions(
            language: language,
            showNative: showNative,
            translateLabel: showNative ? '日本語で見る' : '${language.label}で見る',
            audioLabel: '操作案内の音声',
            onToggleNative: onToggleNative,
            onAudio: () => LearningAudio.play(
              context,
              AudioCueFactory.instruction(
                namespace: 'lesson.supported_instruction',
                label: '操作案内',
                text: line.japanese,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockActivityPanel extends StatelessWidget {
  final _ClockScenario scenario;
  final int offset;
  final bool locked;
  final ValueChanged<int> onChangeOffset;

  const _ClockActivityPanel({
    required this.scenario,
    required this.offset,
    required this.locked,
    required this.onChangeOffset,
  });

  @override
  Widget build(BuildContext context) {
    final currentTotal = scenario.hour * 60 + scenario.minute + offset;
    final targetReached = offset == scenario.targetOffset;
    final clock = _AnalogTimeClock(
      startTotalMinutes: scenario.hour * 60 + scenario.minute,
      totalMinutes: currentTotal,
      progress: scenario.targetOffset == 0
          ? 0
          : offset.abs() / scenario.targetOffset.abs(),
    );
    final timeSummary = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatTime(currentTotal),
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '動かした時間：${offset.abs()}分',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
          ),
        ),
        if (targetReached) ...[
          const SizedBox(height: 10),
          Text(
            scenario.targetOffset < 0 ? '時計を戻せたね。' : scenario.completionMessage,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ],
    );
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: locked ? null : () => onChangeOffset(5),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            minimumSize: const Size.fromHeight(46),
          ),
          child: const Text('+5分'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: locked ? null : () => onChangeOffset(-5),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF93C5FD)),
            minimumSize: const Size.fromHeight(46),
          ),
          child: const Text('-5分'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              clock,
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 112, child: controls),
                  const SizedBox(width: 18),
                  timeSummary,
                ],
              ),
            ],
          );
        }

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 112, child: controls),
              const SizedBox(width: 22),
              clock,
              const SizedBox(width: 28),
              timeSummary,
            ],
          ),
        );
      },
    );
  }
}

class _AnalogTimeClock extends StatelessWidget {
  final int startTotalMinutes;
  final int totalMinutes;
  final double progress;

  const _AnalogTimeClock({
    this.startTotalMinutes = 0,
    required this.totalMinutes,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(210, 210),
      painter: _AnalogTimeClockPainter(
        startTotalMinutes: startTotalMinutes,
        totalMinutes: totalMinutes,
        progress: progress.clamp(0, 1),
      ),
    );
  }
}

class _AnalogTimeClockPainter extends CustomPainter {
  final int startTotalMinutes;
  final int totalMinutes;
  final double progress;

  const _AnalogTimeClockPainter({
    required this.startTotalMinutes,
    required this.totalMinutes,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center, radius, rimPaint);

    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final majorTickPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + i / 60 * math.pi * 2;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final isMajor = i % 5 == 0;
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (isMajor ? 12 : 6));
      canvas.drawLine(inner, outer, isMajor ? majorTickPaint : tickPaint);
    }

    for (var hour = 1; hour <= 12; hour++) {
      final angle = -math.pi / 2 + hour / 12 * math.pi * 2;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 28);
      final painter = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: const TextStyle(
            fontFamily: AppFonts.interface,
            color: Color(0xFF334155),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final minutesInHour = totalMinutes % 60;
    final hourInTwelve = (totalMinutes / 60) % 12;
    final minuteAngle = -math.pi / 2 + minutesInHour / 60 * math.pi * 2;
    final hourAngle = -math.pi / 2 + hourInTwelve / 12 * math.pi * 2;
    final handPaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * .5),
      handPaint,
    );
    handPaint.strokeWidth = 3;
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * .78),
      handPaint,
    );
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(covariant _AnalogTimeClockPainter oldDelegate) {
    return startTotalMinutes != oldDelegate.startTotalMinutes ||
        totalMinutes != oldDelegate.totalMinutes ||
        progress != oldDelegate.progress;
  }
}

class _TimeResultBox extends StatefulWidget {
  final _TimeLearnPage page;
  final AppLanguage selectedLanguage;

  const _TimeResultBox({required this.page, required this.selectedLanguage});

  @override
  State<_TimeResultBox> createState() => _TimeResultBoxState();
}

class _TimeResultBoxState extends State<_TimeResultBox> {
  bool _showNative = false;

  String get _nativeAnswer {
    final isArrival = widget.page.answer == '午前8時10分';
    return switch (widget.selectedLanguage) {
      AppLanguage.portuguese =>
        isArrival ? '8:10 da manhã' : '1 hora e 10 minutos',
      AppLanguage.tagalog =>
        isArrival ? '8:10 ng umaga' : '1 oras at 10 minuto',
      AppLanguage.vietnamese =>
        isArrival ? '8 gio 10 phut sang' : '1 gio 10 phut',
      AppLanguage.japanese => '',
    };
  }

  String get _nativeExplanation {
    final isArrival = widget.page.answer == '午前8時10分';
    return switch (widget.selectedLanguage) {
      AppLanguage.portuguese =>
        isArrival
            ? 'Foram 20 minutos ate as 8:00 e mais 10 minutos ate as 8:10. Por isso, a chegada foi as 8:10 da manha.'
            : 'Das 3:40 ate as 4:00 sao 20 minutos, e das 4:00 ate as 4:50 sao mais 50 minutos. 20 + 50 = 70 minutos, ou 1 hora e 10 minutos.',
      AppLanguage.tagalog =>
        isArrival
            ? '20 minuto hanggang 8:00 at 10 minuto mula 8:00 hanggang 8:10. Kaya dumating nang 8:10 ng umaga.'
            : '20 minuto mula 3:40 hanggang 4:00 at 50 minuto mula 4:00 hanggang 4:50. Ang 20 + 50 ay 70 minuto, o 1 oras at 10 minuto.',
      AppLanguage.vietnamese =>
        isArrival
            ? 'Can 20 phut den 8 gio va 10 phut tu 8 gio den 8 gio 10. Vi vay den truong luc 8 gio 10 sang.'
            : 'Tu 3 gio 40 den 4 gio la 20 phut, va tu 4 gio den 4 gio 50 la 50 phut. 20 + 50 = 70 phut, hay 1 gio 10 phut.',
      AppLanguage.japanese => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.page.answer,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    color: Color(0xFF111827),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _IconSupportActions(
                language: widget.selectedLanguage,
                showNative: _showNative,
                translateLabel: _showNative
                    ? '日本語で見る'
                    : '${widget.selectedLanguage.label}で見る',
                audioLabel: '答えの説明を聞く',
                onToggleNative: () {
                  setState(() => _showNative = !_showNative);
                },
                onAudio: () => LearningAudio.speakJapanese(
                  context,
                  label: '答えの説明',
                  text: '${widget.page.answer}。${widget.page.explanation}',
                ),
              ),
            ],
          ),
          if (_showNative && _nativeAnswer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 2),
              child: Text(
                _nativeAnswer,
                style: const TextStyle(
                  fontFamily: AppFonts.interface,
                  color: Color(0xFF047857),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            widget.page.explanation,
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_showNative && _nativeExplanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _nativeExplanation,
              style: const TextStyle(
                fontFamily: AppFonts.interface,
                color: Color(0xFF047857),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < widget.page.splitLabels.length; i++)
                _SplitClockCard(
                  label: widget.page.splitLabels[i],
                  startTotalMinutes:
                      widget.page.scenario.hour * 60 +
                      widget.page.scenario.minute +
                      widget.page.splitMinutes
                          .take(i)
                          .fold(0, (sum, value) => sum + value),
                  minutes: widget.page.splitMinutes[i],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TimeRuler(
            startTotalMinutes:
                widget.page.scenario.hour * 60 + widget.page.scenario.minute,
            labels: widget.page.timelineLabels,
            spans: widget.page.splitLabels,
            splitMinutes: widget.page.splitMinutes,
          ),
        ],
      ),
    );
  }
}

class _SplitClockCard extends StatelessWidget {
  final String label;
  final int startTotalMinutes;
  final int minutes;

  const _SplitClockCard({
    required this.label,
    required this.startTotalMinutes,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(132, 132),
            painter: _MiniArcClockPainter(
              startTotalMinutes: startTotalMinutes,
              endTotalMinutes: startTotalMinutes + minutes,
              minutes: minutes,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniArcClockPainter extends CustomPainter {
  final int startTotalMinutes;
  final int endTotalMinutes;
  final int minutes;

  const _MiniArcClockPainter({
    required this.startTotalMinutes,
    required this.endTotalMinutes,
    required this.minutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final majorTickPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + i / 60 * math.pi * 2;
      final isMajor = i % 5 == 0;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (isMajor ? 9 : 5));
      canvas.drawLine(inner, outer, isMajor ? majorTickPaint : tickPaint);
    }

    for (var hour = 1; hour <= 12; hour++) {
      final angle = -math.pi / 2 + hour / 12 * math.pi * 2;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 22);
      final painter = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: const TextStyle(
            fontFamily: AppFonts.interface,
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final startMinute = startTotalMinutes % 60;
    final arcStart = -math.pi / 2 + startMinute / 60 * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      arcStart,
      minutes / 60 * math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    _drawClockHands(
      canvas,
      center,
      radius,
      startTotalMinutes,
      const Color(0x66111827),
      2.5,
    );
    _drawClockHands(
      canvas,
      center,
      radius,
      endTotalMinutes,
      const Color(0xFF111827),
      4,
    );
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF2563EB));
  }

  void _drawClockHands(
    Canvas canvas,
    Offset center,
    double radius,
    int totalMinutes,
    Color color,
    double strokeWidth,
  ) {
    final minutesInHour = totalMinutes % 60;
    final hourInTwelve = (totalMinutes / 60) % 12;
    final minuteAngle = -math.pi / 2 + minutesInHour / 60 * math.pi * 2;
    final hourAngle = -math.pi / 2 + hourInTwelve / 12 * math.pi * 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * .45),
      paint,
    );
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * .72),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniArcClockPainter oldDelegate) {
    return startTotalMinutes != oldDelegate.startTotalMinutes ||
        endTotalMinutes != oldDelegate.endTotalMinutes ||
        minutes != oldDelegate.minutes;
  }
}

class _TimeRuler extends StatelessWidget {
  final int startTotalMinutes;
  final List<String> labels;
  final List<String> spans;
  final List<int> splitMinutes;

  const _TimeRuler({
    required this.startTotalMinutes,
    required this.labels,
    required this.spans,
    required this.splitMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: CustomPaint(
        painter: _TimeRulerPainter(
          startTotalMinutes: startTotalMinutes,
          labels: labels,
          spans: spans,
          splitMinutes: splitMinutes,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final int startTotalMinutes;
  final List<String> labels;
  final List<String> spans;
  final List<int> splitMinutes;

  const _TimeRulerPainter({
    required this.startTotalMinutes,
    required this.labels,
    required this.spans,
    required this.splitMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalMinutes = splitMinutes.fold<int>(0, (sum, value) => sum + value);
    if (totalMinutes <= 0) return;

    const left = 24.0;
    final right = size.width - 24;
    const y = 42.0;
    final width = right - left;
    canvas.drawLine(
      const Offset(left, y),
      Offset(right, y),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    for (var minute = 0; minute <= totalMinutes; minute += 10) {
      final total = startTotalMinutes + minute;
      final x = left + width * minute / totalMinutes;
      final isHour = total % 60 == 0;
      canvas.drawLine(
        Offset(x, y - (isHour ? 20 : 13)),
        Offset(x, y + (isHour ? 20 : 13)),
        Paint()
          ..color = isHour ? const Color(0xFF475569) : const Color(0xFF64748B)
          ..strokeWidth = isHour ? 2.8 : 2
          ..strokeCap = StrokeCap.round,
      );
    }

    var elapsed = 0;
    for (var i = 0; i < splitMinutes.length; i++) {
      final startX = left + width * elapsed / totalMinutes;
      elapsed += splitMinutes[i];
      final endX = left + width * elapsed / totalMinutes;
      const arrowY = y - 28;
      canvas.drawLine(
        Offset(startX, arrowY),
        Offset(math.max(startX, endX - 12), arrowY),
        Paint()
          ..color = const Color(0xFF2563EB)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      final path = Path()
        ..moveTo(endX, arrowY)
        ..lineTo(endX - 10, arrowY - 6)
        ..lineTo(endX - 10, arrowY + 6)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF2563EB));
      _paintText(
        canvas,
        spans[i],
        Offset((startX + endX) / 2, arrowY - 17),
        13,
        color: const Color(0xFF2563EB),
      );
    }

    final labelPositions = <double>[0];
    var sum = 0;
    for (final minutes in splitMinutes) {
      sum += minutes;
      labelPositions.add(sum / totalMinutes);
    }
    for (var i = 0; i < labels.length && i < labelPositions.length; i++) {
      final x = left + width * labelPositions[i];
      _paintText(
        canvas,
        labels[i],
        Offset(x, y + 38),
        12,
        color: const Color(0xFF334155),
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize, {
    Color color = const Color(0xFF475569),
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return startTotalMinutes != oldDelegate.startTotalMinutes ||
        labels != oldDelegate.labels ||
        spans != oldDelegate.spans ||
        splitMinutes != oldDelegate.splitMinutes;
  }
}

String _formatTime(int totalMinutes) {
  final normalized = totalMinutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '$hour時${minute.toString().padLeft(2, '0')}分';
}

class _SecondHandPanel extends StatelessWidget {
  final AppLanguage selectedLanguage;

  const _SecondHandPanel({required this.selectedLanguage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: [_SecondClockCard(), _StopwatchSecondCard()],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '60秒 = 1分',
            style: TextStyle(
              fontFamily: AppFonts.display,
              color: Color(0xFF2563EB),
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _InlineExplanationSupport(
            line: const SupportLine(
              japanese: '秒針が1目もり進むと1秒。ストップウォッチの数字が1ふえると1秒です。',
              ruby:
                  '{秒針|びょうしん}が1{目|め}もり{進|すす}むと1{秒|びょう}。ストップウォッチの{数字|すうじ}が1ふえると1{秒|びょう}です。',
              native: {
                AppLanguage.portuguese:
                    'Quando o ponteiro dos segundos avanca uma marca, passa 1 segundo. Quando o numero do cronometro aumenta 1, passa 1 segundo.',
                AppLanguage.tagalog:
                    'Kapag umusad ng isang marka ang segundo na kamay, isang segundo ang lumilipas. Kapag nadagdagan ng 1 ang numero ng stopwatch, isang segundo ang lumilipas.',
                AppLanguage.vietnamese:
                    'Kim giay tien mot vach la 1 giay. So tren dong ho bam gio tang them 1 la 1 giay.',
              },
            ),
            language: selectedLanguage,
            vocabularyEntries: _timeVocabularyEntries,
            backgroundColor: const Color(0xFFECFDF5),
          ),
        ],
      ),
    );
  }
}

class _SecondClockCard extends StatefulWidget {
  const _SecondClockCard();

  @override
  State<_SecondClockCard> createState() => _SecondClockCardState();
}

class _SecondClockCardState extends State<_SecondClockCard> {
  var _cycle = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 248,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(_cycle),
            tween: Tween(begin: 0, end: 60),
            duration: const Duration(seconds: 12),
            onEnd: () {
              if (!mounted) return;
              setState(() {
                _cycle++;
              });
            },
            builder: (context, second, _) {
              return CustomPaint(
                size: const Size(178, 178),
                painter: _SecondClockPainter(second: second),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            '赤い針が秒針',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondClockPainter extends CustomPainter {
  final double second;

  const _SecondClockPainter({required this.second});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()
        ..color = const Color(0x12000000)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + i / 60 * math.pi * 2;
      final isMajor = i % 5 == 0;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (isMajor ? 11 : 6));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = isMajor ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)
          ..strokeWidth = isMajor ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var hour = 1; hour <= 12; hour++) {
      final angle = -math.pi / 2 + hour / 12 * math.pi * 2;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 26);
      final painter = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: const TextStyle(
            fontFamily: AppFonts.interface,
            color: Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final hourAngle = -math.pi / 2 + (10 + second / 3600) / 12 * math.pi * 2;
    final minuteAngle = -math.pi / 2 + (10 + second / 60) / 60 * math.pi * 2;
    final handPaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(hourAngle), math.sin(hourAngle)) * (radius * .46),
      handPaint,
    );
    handPaint.strokeWidth = 3.5;
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * (radius * .68),
      handPaint,
    );

    final secondAngle = -math.pi / 2 + (second % 60) / 60 * math.pi * 2;
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(secondAngle), math.sin(secondAngle)) * (radius - 12),
      Paint()
        ..color = const Color(0xFFDC2626)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(center, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SecondClockPainter oldDelegate) {
    return second != oldDelegate.second;
  }
}

class _StopwatchSecondCard extends StatefulWidget {
  const _StopwatchSecondCard();

  @override
  State<_StopwatchSecondCard> createState() => _StopwatchSecondCardState();
}

class _StopwatchSecondCardState extends State<_StopwatchSecondCard> {
  var _cycle = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 248,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(_cycle),
            tween: Tween(begin: 0, end: 60),
            duration: const Duration(seconds: 12),
            onEnd: () {
              if (mounted) {
                setState(() {
                  _cycle++;
                });
              }
            },
            builder: (context, value, _) {
              final seconds = value.floor().clamp(0, 59);
              return SizedBox(
                height: 178,
                child: Center(
                  child: Container(
                    width: 184,
                    height: 112,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1F2937), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'STOPWATCH',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: 0,
                            ),
                            children: [
                              const TextSpan(text: '00:'),
                              TextSpan(
                                text: seconds.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'SECONDS',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            '赤文字が秒数',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinuteSecondPanel extends StatelessWidget {
  final AppLanguage selectedLanguage;

  const _MinuteSecondPanel({required this.selectedLanguage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: const [
              _StaticStopwatchDisplay(),
              Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF64748B),
                size: 34,
              ),
              _SecondsOnlyDisplay(),
            ],
          ),
          const SizedBox(height: 18),
          _InlineExplanationSupport(
            line: const SupportLine(
              japanese: '1分は60秒。だから、1分20秒は80秒です。',
              ruby: '1{分|ぷん}は60{秒|びょう}。だから、1{分|ぷん}20{秒|びょう}は80{秒|びょう}です。',
              native: {
                AppLanguage.portuguese:
                    '1 minuto tem 60 segundos. Por isso, 1 minuto e 20 segundos sao 80 segundos.',
                AppLanguage.tagalog:
                    'Ang 1 minuto ay 60 segundo. Kaya ang 1 minuto at 20 segundo ay 80 segundo.',
                AppLanguage.vietnamese:
                    '1 phut la 60 giay. Vi vay, 1 phut 20 giay la 80 giay.',
              },
            ),
            language: selectedLanguage,
            vocabularyEntries: _timeVocabularyEntries,
            backgroundColor: const Color(0xFFECFDF5),
          ),
        ],
      ),
    );
  }
}

class _InlineExplanationSupport extends StatefulWidget {
  final SupportLine line;
  final AppLanguage language;
  final List<VocabularyEntry> vocabularyEntries;
  final Color backgroundColor;

  const _InlineExplanationSupport({
    required this.line,
    required this.language,
    this.vocabularyEntries = const [],
    this.backgroundColor = const Color(0xFFF8FAFC),
  });

  @override
  State<_InlineExplanationSupport> createState() =>
      _InlineExplanationSupportState();
}

class _InlineExplanationSupportState extends State<_InlineExplanationSupport> {
  bool _showNative = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SupportedTextLines(
              lines: [widget.line],
              language: widget.language,
              showNative: _showNative,
              vocabularyEntries: widget.vocabularyEntries,
              enableLearningSupport: true,
            ),
          ),
          const SizedBox(width: 10),
          _IconSupportActions(
            language: widget.language,
            showNative: _showNative,
            translateLabel: _showNative
                ? '日本語で見る'
                : '${widget.language.label}で見る',
            audioLabel: '説明の音声',
            onToggleNative: () => setState(() => _showNative = !_showNative),
            onAudio: () => LearningAudio.speakJapanese(
              context,
              label: '説明',
              text: widget.line.japanese,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticStopwatchDisplay extends StatelessWidget {
  const _StaticStopwatchDisplay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 124,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2937), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'STOPWATCH',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.display,
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: 0,
              ),
              children: [
                TextSpan(text: '01'),
                TextSpan(text: ':'),
                TextSpan(
                  text: '20',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'MIN : SEC',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondsOnlyDisplay extends StatelessWidget {
  const _SecondsOnlyDisplay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 124,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        '80秒',
        style: TextStyle(
          fontFamily: AppFonts.display,
          color: Color(0xFF2563EB),
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _LengthMeasureLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _LengthMeasureLearn({required this.selectedLanguage});

  @override
  State<_LengthMeasureLearn> createState() => _LengthMeasureLearnState();
}

class _LengthMeasureLearnState extends State<_LengthMeasureLearn> {
  int _page = 0;
  Offset _rulerPosition = const Offset(104, 124);
  double _tapeValue = 0;
  bool _showNative = false;
  bool _showRulerGuideNative = false;
  bool _showTapeGuideNative = false;

  static const _lastPage = 1;

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: '長さ',
      text: _pageLines.first.japanese,
    );
  }

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => [
        SupportLine(
          japanese: 'えんぴつの長さをはかりましょう。',
          ruby: 'えんぴつの{長|なが}さをはかりましょう。',
          native: nativeText(
            portuguese: 'Vamos medir o comprimento do lápis.',
            tagalog: 'Sukatin natin ang haba ng lapis.',
            vietnamese: 'Hãy đo chiều dài bút chì.',
          ),
        ),
      ],
      1 => [
        SupportLine(
          japanese: 'ろうかの長さをまきじゃくではかりましょう。',
          ruby: 'ろうかの{長|なが}さをまきじゃくではかりましょう。',
          native: nativeText(
            portuguese:
                'Vamos medir o comprimento do corredor com uma fita métrica.',
            tagalog:
                'Sukatin natin ang haba ng pasilyo gamit ang tape measure.',
            vietnamese: 'Hãy đo chiều dài hành lang bằng thước dây.',
          ),
        ),
      ],
      2 => [
        SupportLine(
          japanese: '木のみきをはかりましょう。',
          ruby: '{木|き}のみきをはかりましょう。',
          native: nativeText(
            portuguese: 'Vamos medir o tronco da árvore.',
            tagalog: 'Sukatin natin ang puno ng kahoy.',
            vietnamese: 'Hãy đo thân cây.',
          ),
        ),
      ],
      _ => [
        SupportLine(
          japanese: 'はかるものに合わせて、ものさしとまきじゃくを選びます。',
          ruby: 'はかるものに{合|あ}わせて、ものさしとまきじゃくを{選|えら}びます。',
          native: nativeText(
            portuguese:
                'Escolhemos régua ou fita métrica de acordo com o que vamos medir.',
            tagalog:
                'Pumili tayo ng ruler o tape measure ayon sa susukatin.',
            vietnamese:
                'Chọn thước kẻ hoặc thước dây tùy theo thứ cần đo.',
          ),
        ),
      ],
    };
  }

  static final _rulerGuide = SupportLine(
    japanese: 'ものさしを動かして、0をえんぴつの左のはしに合わせよう。',
    ruby: 'ものさしを{動|うご}かして、0をえんぴつの{左|ひだり}のはしに{合|あ}わせよう。',
    native: nativeText(
      portuguese:
          'Mova a régua e alinhe o zero com a ponta esquerda do lápis.',
      tagalog:
          'Igagalaw ang ruler at itapat ang 0 sa kaliwang dulo ng lapis.',
      vietnamese:
          'Di chuyển thước kẻ và đặt vạch 0 sát mép trái bút chì.',
    ),
  );

  static final _tapeGuide = SupportLine(
    japanese: 'まきじゃくの先を引っぱって、ろうかのはしまでのばそう。',
    ruby: 'まきじゃくの{先|さき}を{引|ひ}っぱって、ろうかのはしまでのばそう。',
    native: nativeText(
      portuguese:
          'Puxe a ponta da fita métrica até o fim do corredor.',
      tagalog:
          'Hilahin ang dulo ng tape measure hanggang sa dulo ng pasilyo.',
      vietnamese:
          'Kéo đầu thước dây đến hết hành lang.',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _RemainderLearnShell(
      icon: Icons.straighten_rounded,
      title: '長さに合う道具を選ぼう',
      titleVocabularyEntries: _lengthVocabularyEntries,
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () => setState(() {
        final next = !_showNative;
        _showNative = next;
        _showRulerGuideNative = next;
        _showTapeGuideNative = next;
      }),
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: () {
        if (_page == 0) return;
        setState(() => _page--);
      },
      onNext: () {
        if (_page == _lastPage) return;
        setState(() => _page++);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SupportedTextLines(
            lines: _pageLines,
            language: widget.selectedLanguage,
            showNative: _showNative,
            vocabularyEntries: _lengthVocabularyEntries,
            enableLearningSupport: true,
          ),
          if (_page == 0) ...[
            const SizedBox(height: 12),
            _SupportedInstruction(
              line: _rulerGuide,
              language: widget.selectedLanguage,
              showNative: _showRulerGuideNative,
              onToggleNative: () {
                setState(() => _showRulerGuideNative = !_showRulerGuideNative);
              },
              vocabularyEntries: _lengthVocabularyEntries,
            ),
          ],
          if (_page == 1) ...[
            const SizedBox(height: 12),
            _SupportedInstruction(
              line: _tapeGuide,
              language: widget.selectedLanguage,
              showNative: _showTapeGuideNative,
              onToggleNative: () {
                setState(() => _showTapeGuideNative = !_showTapeGuideNative);
              },
              vocabularyEntries: _lengthVocabularyEntries,
            ),
          ],
          const SizedBox(height: 18),
          switch (_page) {
            0 => _InteractiveRulerPanel(
              rulerPosition: _rulerPosition,
              onChanged: (value) => setState(() => _rulerPosition = value),
              language: widget.selectedLanguage,
            ),
            1 => _InteractiveTapeMeasurePanel(
              value: _tapeValue,
              onChanged: (value) => setState(() => _tapeValue = value),
              language: widget.selectedLanguage,
            ),
            2 => _CurvedTapePanel(language: widget.selectedLanguage),
            _ => const _ToolChoiceSummaryPanel(),
          },
        ],
      ),
    );
  }
}

class _InteractiveRulerPanel extends StatelessWidget {
  final Offset rulerPosition;
  final ValueChanged<Offset> onChanged;
  final AppLanguage language;

  const _InteractiveRulerPanel({
    required this.rulerPosition,
    required this.onChanged,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = constraints.maxWidth;
        const boardHeight = 300.0;
        const rulerWidth = 520.0;
        const rulerHeight = 76.0;
        final usableRulerWidth = math.min(rulerWidth, boardWidth - 36);
        final cmWidth = usableRulerWidth / 15;
        final pencilLeft = math.max(32.0, (boardWidth - cmWidth * 8) / 2);
        final pencilTop = 42.0;
        final pencilWidth = cmWidth * 8;
        const targetTop = 132.0;
        final isMeasured =
            (rulerPosition.dx - pencilLeft).abs() < 12 &&
            (rulerPosition.dy - targetTop).abs() < 16;

        Offset clampPosition(Offset position) {
          final maxX = math.max(18.0, boardWidth - usableRulerWidth - 18);
          return Offset(
            position.dx.clamp(18.0, maxX).toDouble(),
            position.dy.clamp(102.0, boardHeight - rulerHeight - 14).toDouble(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: boardHeight,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: pencilLeft,
                    top: pencilTop,
                    child: _PencilObject(width: pencilWidth),
                  ),
                  Positioned(
                    left: pencilLeft,
                    top: pencilTop + 52,
                    child: Container(
                      width: 2,
                      height: 150,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  Positioned(
                    left: pencilLeft + pencilWidth,
                    top: pencilTop + 52,
                    child: Container(
                      width: 2,
                      height: 150,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  Positioned(
                    left: rulerPosition.dx,
                    top: rulerPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        // A small finger movement should move the ruler far enough
                        // to feel direct on touch screens.
                        onChanged(
                          clampPosition(rulerPosition + details.delta * 1.7),
                        );
                      },
                      child: _RealisticRuler(
                        width: usableRulerWidth,
                        height: rulerHeight,
                        highlightedCentimeters: isMeasured ? 8 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isMeasured) ...[
              const SizedBox(height: 12),
              _PencilMeasuredResult(language: language),
            ],
          ],
        );
      },
    );
  }
}

class _PencilObject extends StatelessWidget {
  final double width;

  const _PencilObject({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: CustomPaint(painter: _PencilPainter()),
    );
  }
}

class _PencilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromLTRBR(
      0,
      9,
      size.width - 26,
      size.height - 9,
      const Radius.circular(6),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawLine(
      const Offset(18, 11),
      Offset(size.width - 32, 11),
      Paint()
        ..color = const Color(0xFFFFF7ED)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(18, size.height - 11),
      Offset(size.width - 32, size.height - 11),
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 3,
    );
    final eraser = RRect.fromLTRBR(
      0,
      9,
      22,
      size.height - 9,
      const Radius.circular(6),
    );
    canvas.drawRRect(eraser, Paint()..color = const Color(0xFFFCA5A5));
    canvas.drawRect(
      Rect.fromLTWH(22, 9, 8, size.height - 18),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    final path = Path()
      ..moveTo(size.width - 26, 9)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 26, size.height - 9)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFBBF24));
    final lead = Path()
      ..moveTo(size.width - 10, size.height * .38)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 10, size.height * .62)
      ..close();
    canvas.drawPath(lead, Paint()..color = const Color(0xFF334155));
  }

  @override
  bool shouldRepaint(covariant _PencilPainter oldDelegate) => false;
}

class _RealisticRuler extends StatelessWidget {
  final double width;
  final double height;
  final int? highlightedCentimeters;

  const _RealisticRuler({
    required this.width,
    required this.height,
    this.highlightedCentimeters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _RealisticRulerPainter(
          highlightedCentimeters: highlightedCentimeters,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RealisticRulerPainter extends CustomPainter {
  final int? highlightedCentimeters;

  const _RealisticRulerPainter({this.highlightedCentimeters});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFD6A43B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    const cmCount = 15;
    final cm = size.width / cmCount;

    if (highlightedCentimeters != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, cm * highlightedCentimeters!, size.height),
        Paint()..color = const Color(0xFFDBEAFE).withOpacity(0.65),
      );
    }

    for (var centimeter = 0; centimeter <= cmCount; centimeter++) {
      final x = cm * centimeter;
      final isLongMarker = centimeter % 5 == 0;
      final markerColor = isLongMarker
          ? const Color(0xFF111827)
          : const Color(0xFF334155);
      final h = centimeter % 5 == 0 ? 38.0 : 27.0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = markerColor
          ..strokeWidth = isLongMarker ? 2.8 : 1.6,
      );
      final shouldShowMeasuredNumber =
          highlightedCentimeters != null &&
          centimeter == highlightedCentimeters;
      if (isLongMarker || shouldShowMeasuredNumber) {
        _paintText(
          canvas,
          '$centimeter',
          Offset(x, 54),
          shouldShowMeasuredNumber ? 18 : 14,
          shouldShowMeasuredNumber
              ? const Color(0xFF2563EB)
              : const Color(0xFF111827),
        );
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RealisticRulerPainter oldDelegate) {
    return highlightedCentimeters != oldDelegate.highlightedCentimeters;
  }
}

class _MiniRuler extends StatelessWidget {
  final String lengthLabel;

  const _MiniRuler({required this.lengthLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: CustomPaint(
        painter: _MiniRulerPainter(lengthLabel),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MiniRulerPainter extends CustomPainter {
  final String lengthLabel;

  const _MiniRulerPainter(this.lengthLabel);

  @override
  void paint(Canvas canvas, Size size) {
    _RealisticRulerPainter().paint(canvas, size);
    final painter = TextPainter(
      text: TextSpan(
        text: lengthLabel,
        style: const TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: 12,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(size.width - painter.width - 8, 32));
  }

  @override
  bool shouldRepaint(covariant _MiniRulerPainter oldDelegate) {
    return lengthLabel != oldDelegate.lengthLabel;
  }
}

class _PencilMeasuredResult extends StatelessWidget {
  final AppLanguage language;

  const _PencilMeasuredResult({required this.language});

  @override
  Widget build(BuildContext context) {
    return _LengthResultBox(
      language: language,
      titlePrefix: 'えんぴつの長さは ',
      answer: '8cm',
      titleSuffix: ' です。',
      nativeTitle: nativeText(
        portuguese: 'O comprimento do lápis é 8 cm.',
        tagalog: '8 cm ang haba ng lapis.',
        vietnamese: 'Chiều dài bút chì là 8 cm.',
      ),
      japaneseLines: const [
        '長い目もりは5cmずつ、小さい目もりは1cmずつです。',
        '短いものは、ものさしやまきじゃくを使ってはかれます。',
      ],
      nativeLines: {
        AppLanguage.portuguese: const [
          'As marcas longas ficam a cada 5 cm, e as marcas pequenas ficam a cada 1 cm.',
          'Para medir coisas curtas, podemos usar régua ou fita métrica.',
        ],
        AppLanguage.tagalog: const [
          'Ang mahahabang marka ay tig-5 cm, at ang maliliit na marka ay tig-1 cm.',
          'Ang maiikling bagay ay masusukat gamit ang ruler o tape measure.',
        ],
        AppLanguage.vietnamese: const [
          'Vạch dài cách nhau 5 cm, vạch nhỏ cách nhau 1 cm.',
          'Đồ ngắn có thể đo bằng thước kẻ hoặc thước dây.',
        ],
      },
      audioText:
          'えんぴつの長さは8センチメートルです。長い目もりは5センチメートルずつ、小さい目もりは1センチメートルずつです。短いものは、ものさしやまきじゃくを使ってはかれます。',
    );
  }
}

class _LengthResultBox extends StatefulWidget {
  final AppLanguage language;
  final String titlePrefix;
  final String answer;
  final String titleSuffix;
  final Map<AppLanguage, String> nativeTitle;
  final List<String> japaneseLines;
  final Map<AppLanguage, List<String>> nativeLines;
  final String audioText;

  const _LengthResultBox({
    required this.language,
    required this.titlePrefix,
    required this.answer,
    required this.titleSuffix,
    required this.nativeTitle,
    required this.japaneseLines,
    required this.nativeLines,
    required this.audioText,
  });

  @override
  State<_LengthResultBox> createState() => _LengthResultBoxState();
}

class _LengthResultBoxState extends State<_LengthResultBox> {
  bool _showNative = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: AppFonts.interface,
          color: Color(0xFF064E3B),
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w800,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            color: Color(0xFF064E3B),
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(text: widget.titlePrefix),
                            TextSpan(
                              text: widget.answer,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 32,
                              ),
                            ),
                            TextSpan(text: widget.titleSuffix),
                          ],
                        ),
                      ),
                      if (_showNative &&
                          widget.language != AppLanguage.japanese &&
                          widget.nativeTitle[widget.language] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.nativeTitle[widget.language]!,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _IconSupportActions(
                  language: widget.language,
                  showNative: _showNative,
                  translateLabel: widget.language.label,
                  audioLabel: '音声',
                  onToggleNative: () {
                    setState(() => _showNative = !_showNative);
                  },
                  onAudio: () {
                    LearningAudio.speakJapanese(
                      context,
                      label: '長さ',
                      text: widget.audioText,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in widget.japaneseLines) Text(line),
            if (_showNative) ...[
              const SizedBox(height: 8),
              for (final line in widget.nativeLines[widget.language] ??
                  const <String>[])
                Text(
                  line,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InteractiveTapeMeasurePanel extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final AppLanguage language;

  const _InteractiveTapeMeasurePanel({
    required this.value,
    required this.onChanged,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isMeasured = value >= 5.85;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _TapeMeasureBar(value: value, maxMeters: 6, onChanged: onChanged),
            ],
          ),
        ),
        if (isMeasured)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _LengthResultBox(
              language: language,
              titlePrefix: 'ろうかの長さは ',
              answer: '6m',
              titleSuffix: ' でした。',
              nativeTitle: nativeText(
                portuguese: 'O comprimento do corredor é 6 m.',
                tagalog: '6 m ang haba ng pasilyo.',
                vietnamese: 'Chiều dài hành lang là 6 m.',
              ),
              japaneseLines: const ['長いものをはかるときには、まきじゃくを使います。'],
              nativeLines: {
                AppLanguage.portuguese: const [
                  'Para medir coisas compridas, usamos uma fita métrica.',
                ],
                AppLanguage.tagalog: const [
                  'Para sa mahahabang bagay, gumagamit tayo ng tape measure.',
                ],
                AppLanguage.vietnamese: const [
                  'Khi đo đồ dài, ta dùng thước dây.',
                ],
              },
              audioText: 'ろうかの長さは6メートルでした。長いものをはかるときには、まきじゃくを使います。',
            ),
          ),
      ],
    );
  }
}

class _TapeMeasureBar extends StatelessWidget {
  final double value;
  final int maxMeters;
  final ValueChanged<double> onChanged;

  const _TapeMeasureBar({
    required this.value,
    required this.maxMeters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tapeStart = 78.0;
        final tapeEnd = constraints.maxWidth - 34;
        final tapeWidth = tapeEnd - tapeStart;
        final progress = (value / maxMeters).clamp(0.0, 1.0);
        final handleLeft = tapeStart + tapeWidth * progress - 26;

        return SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HallwayTapeMeasurePainter(
                    value: value,
                    maxMeters: maxMeters,
                  ),
                ),
              ),
              Positioned(
                left: handleLeft,
                top: 155,
                child: Semantics(
                  label: 'まきじゃくの先を引っぱる',
                  slider: true,
                  value: '${value.round()}メートル',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      // Keep the pull tab responsive on touch screens.
                      final next =
                          (value + details.delta.dx / tapeWidth * maxMeters * 4)
                              .clamp(0.0, maxMeters)
                              .toDouble();
                      onChanged(next);
                    },
                    child: const SizedBox(width: 52, height: 62),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HallwayTapeMeasurePainter extends CustomPainter {
  final double value;
  final int maxMeters;

  const _HallwayTapeMeasurePainter({
    required this.value,
    required this.maxMeters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Rect.fromLTWH(0, 0, size.width, size.height * .66);
    final floor = Rect.fromLTWH(
      0,
      wall.bottom,
      size.width,
      size.height - wall.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRect(wall, Paint()..color = const Color(0xFFEFF6FF));
    canvas.drawRect(floor, Paint()..color = const Color(0xFFE5E7EB));
    canvas.drawLine(
      Offset(0, wall.bottom),
      Offset(size.width, wall.bottom),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2,
    );

    _paintWindows(canvas, size, wall.bottom);

    final origin = Offset(78, size.height * .74);
    final endX = size.width - 34;
    final tapeWidth = endX - origin.dx;
    final progress = (value / maxMeters).clamp(0.0, 1.0);
    final tapeEndX = origin.dx + tapeWidth * progress;
    final wholeMeters = value.floor();

    _paintTapeCase(canvas, Offset(20, origin.dy - 34));

    if (value > 0) {
      final tapeRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(origin.dx, origin.dy - 12, tapeEndX, origin.dy + 12),
        const Radius.circular(3),
      );
      canvas.drawRRect(tapeRect, Paint()..color = const Color(0xFFFDE68A));
      canvas.drawRRect(
        tapeRect,
        Paint()
          ..color = const Color(0xFF111827)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (var i = 0; i <= wholeMeters; i++) {
      final x = origin.dx + tapeWidth * i / maxMeters;
      final isLong = i == 0 || i == maxMeters || i % 2 == 0;
      canvas.drawLine(
        Offset(x, origin.dy - 12),
        Offset(x, origin.dy + (isLong ? 18 : 10)),
        Paint()
          ..color = const Color(0xFF111827)
          ..strokeWidth = isLong ? 2 : 1,
      );
      _paintText(
        canvas,
        '${i}m',
        Offset(x, origin.dy + 32),
        13,
        const Color(0xFF111827),
        FontWeight.w800,
      );
    }

    final pullTab = RRect.fromRectAndRadius(
      Rect.fromLTWH(tapeEndX - 7, origin.dy - 25, 14, 50),
      const Radius.circular(5),
    );
    canvas.drawRRect(pullTab, Paint()..color = const Color(0xFF475569));
    canvas.drawRRect(
      pullTab,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final gripPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final y = origin.dy + i * 9;
      canvas.drawLine(
        Offset(tapeEndX - 3, y),
        Offset(tapeEndX + 3, y),
        gripPaint,
      );
    }

    _paintText(
      canvas,
      'まきじゃく',
      Offset(48, origin.dy + 54),
      12,
      const Color(0xFF475569),
      FontWeight.w800,
    );
  }

  void _paintWindows(Canvas canvas, Size size, double wallBottom) {
    final windowPaint = Paint()..color = const Color(0xFFBFDBFE);
    final framePaint = Paint()
      ..color = const Color(0xFF93A4B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final treePaint = Paint()..color = const Color(0xFF86EFAC);
    final trunkPaint = Paint()..color = const Color(0xFFA16207);

    for (var i = 0; i < 4; i++) {
      final left = 88.0 + i * (size.width - 170) / 3;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 34, 94, 62),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, windowPaint);
      canvas.drawRRect(rect, framePaint);
      canvas.drawLine(Offset(left + 47, 34), Offset(left + 47, 96), framePaint);
      canvas.drawLine(Offset(left, 65), Offset(left + 94, 65), framePaint);
      canvas.drawRect(Rect.fromLTWH(left + 17, 68, 7, 20), trunkPaint);
      canvas.drawCircle(Offset(left + 20, 62), 15, treePaint);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, wallBottom - 9, size.width, 9),
      Paint()..color = const Color(0xFFD7DEE8),
    );
  }

  void _paintTapeCase(Canvas canvas, Offset topLeft) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, 62, 58),
      const Radius.circular(15),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2563EB));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF1E40AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(topLeft.dx + 31, topLeft.dy + 28),
      16,
      Paint()..color = const Color(0xFFEFF6FF),
    );
    canvas.drawCircle(
      Offset(topLeft.dx + 31, topLeft.dy + 28),
      7,
      Paint()..color = const Color(0xFF93C5FD),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _HallwayTapeMeasurePainter oldDelegate) {
    return value != oldDelegate.value || maxMeters != oldDelegate.maxMeters;
  }
}

class _CurvedTapePanel extends StatefulWidget {
  final AppLanguage language;

  const _CurvedTapePanel({required this.language});

  @override
  State<_CurvedTapePanel> createState() => _CurvedTapePanelState();
}

class _CurvedTapePanelState extends State<_CurvedTapePanel> {
  double _rotation = .18;
  double _tapeProgress = 0;

  @override
  Widget build(BuildContext context) {
    final isMeasured = _tapeProgress >= .98;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SoftResultLine(text: '指で木のみきを回してみましょう。'),
        const SizedBox(height: 12),
        Container(
          height: 310,
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                final delta = details.delta.dx;
                _rotation = (_rotation + delta * .012) % (math.pi * 2);
                _tapeProgress = (_tapeProgress + delta.abs() / 340)
                    .clamp(0.0, 1.0)
                    .toDouble();
              });
            },
            child: CustomPaint(
              painter: _TrunkMeasurePainter(
                rotation: _rotation,
                tapeProgress: _tapeProgress,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isMeasured)
          _LengthResultBox(
            language: widget.language,
            titlePrefix: '木のみきのまわりは ',
            answer: '80cm',
            titleSuffix: ' でした。',
            nativeTitle: nativeText(
              portuguese: 'A volta do tronco da árvore tem 80 cm.',
              tagalog: '80 cm ang paligid ng puno ng kahoy.',
              vietnamese: 'Chu vi thân cây là 80 cm.',
            ),
            japaneseLines: const ['まきじゃくは、まるいもののまわりをはかるときに便利です。'],
            nativeLines: {
              AppLanguage.portuguese: const [
                'A fita métrica é útil para medir ao redor de coisas redondas.',
              ],
              AppLanguage.tagalog: const [
                'Maginhawa ang tape measure sa pagsukat sa paligid ng bilog na bagay.',
              ],
              AppLanguage.vietnamese: const [
                'Thước dây tiện khi đo vòng quanh đồ tròn.',
              ],
            },
            audioText: '木のみきのまわりは80センチメートルでした。まきじゃくは、まるいもののまわりをはかるときに便利です。',
          )
        else
          const _SoftResultLine(text: 'まきじゃくの0と、ひとまわりした目もりが重なるところを見つけよう。'),
      ],
    );
  }
}

class _TrunkMeasurePainter extends CustomPainter {
  final double rotation;
  final double tapeProgress;

  const _TrunkMeasurePainter({
    required this.rotation,
    required this.tapeProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .5);
    final trunkWidth = math.min(size.width * .34, 190.0);
    final trunkHeight = size.height * .78;
    final trunkRect = Rect.fromCenter(
      center: center.translate(0, 2),
      width: trunkWidth,
      height: trunkHeight,
    );

    _paintGround(canvas, size, trunkRect);
    final trunkPath = _trunkPath(trunkRect);
    _paintTapeBack(canvas, trunkRect);
    _paintTrunk(canvas, trunkRect, trunkPath);
    _paintBark(canvas, trunkRect, trunkPath);
    _paintTapeFront(canvas, trunkRect);

    _paintText(
      canvas,
      '木のみき',
      Offset(center.dx, trunkRect.top - 16),
      17,
      const Color(0xFF111827),
      FontWeight.w900,
    );
  }

  void _paintGround(Canvas canvas, Size size, Rect trunkRect) {
    final ground = Rect.fromLTRB(
      0,
      trunkRect.bottom - 12,
      size.width,
      size.height,
    );
    canvas.drawRect(ground, Paint()..color = const Color(0xFFE7F5E8));
    for (var i = 0; i < 10; i++) {
      final x = (i + .5) * size.width / 10;
      canvas.drawLine(
        Offset(x, trunkRect.bottom - 2),
        Offset(x - 12, trunkRect.bottom + 18),
        Paint()
          ..color = const Color(0xFF86EFAC)
          ..strokeWidth = 1.4,
      );
    }
  }

  Path _trunkPath(Rect rect) {
    return Path()
      ..moveTo(rect.left + rect.width * .17, rect.top + 8)
      ..cubicTo(
        rect.left + rect.width * .06,
        rect.top + rect.height * .32,
        rect.left + rect.width * .1,
        rect.top + rect.height * .7,
        rect.left + rect.width * .2,
        rect.bottom,
      )
      ..lineTo(rect.right - rect.width * .19, rect.bottom)
      ..cubicTo(
        rect.right - rect.width * .08,
        rect.top + rect.height * .72,
        rect.right - rect.width * .07,
        rect.top + rect.height * .3,
        rect.right - rect.width * .18,
        rect.top + 8,
      )
      ..close();
  }

  void _paintTrunk(Canvas canvas, Rect rect, Path trunkPath) {
    final gradient = LinearGradient(
      colors: const [
        Color(0xFF6B2F12),
        Color(0xFF9A4D16),
        Color(0xFFB7671F),
        Color(0xFF6B2F12),
      ],
      stops: const [0, .28, .62, 1],
    );
    canvas.drawPath(trunkPath, Paint()..shader = gradient.createShader(rect));
    canvas.drawPath(
      trunkPath,
      Paint()
        ..color = const Color(0xFF4A220D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final top = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + 14),
      width: rect.width * .67,
      height: 30,
    );
    canvas.drawOval(top, Paint()..color = const Color(0xFF7C3A12));
    canvas.drawOval(
      top.deflate(7),
      Paint()
        ..color = const Color(0xFFB7791F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _paintBark(Canvas canvas, Rect rect, Path trunkPath) {
    final barkPaint = Paint()
      ..color = const Color(0xFF3F1F0D).withOpacity(.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipPath(trunkPath);
    for (var i = 0; i < 12; i++) {
      final phase = rotation + i * .78;
      final x =
          rect.left + rect.width * (.18 + .64 * ((math.sin(phase) + 1) / 2));
      final top = rect.top + 34 + (i % 4) * 9;
      final path = Path()..moveTo(x, top);
      for (var y = top; y < rect.bottom - 14; y += 34) {
        path.quadraticBezierTo(
          x + math.sin(y * .08 + phase) * 9,
          y + 14,
          x + math.cos(y * .07 + phase) * 5,
          y + 30,
        );
      }
      canvas.drawPath(path, barkPaint);
    }

    for (var i = 0; i < 9; i++) {
      final y = rect.top + 54 + i * 24;
      final x =
          rect.left +
          rect.width * (.3 + .4 * ((math.cos(rotation + i) + 1) / 2));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 18, height: 8),
        Paint()..color = const Color(0xFF4A220D).withOpacity(.24),
      );
    }
    canvas.restore();
  }

  Rect _tapeEllipse(Rect rect) {
    final bandY = rect.top + rect.height * .48;
    return Rect.fromCenter(
      center: Offset(rect.center.dx, bandY),
      width: rect.width * .98,
      height: 54,
    );
  }

  void _paintTapeBack(Canvas canvas, Rect rect) {
    final ellipse = _tapeEllipse(rect);
    const anchorAngle = math.pi / 2;
    final endAngle = anchorAngle + math.pi * 2 * tapeProgress;
    final backStart = math.max(math.pi, anchorAngle);
    final backEnd = math.min(math.pi * 2, endAngle);
    if (backEnd <= backStart) return;

    final backPaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ellipse, backStart, backEnd - backStart, false, backPaint);
  }

  void _paintTapeFront(Canvas canvas, Rect rect) {
    final ellipse = _tapeEllipse(rect);
    const anchorAngle = math.pi / 2;
    final endAngle = anchorAngle + math.pi * 2 * tapeProgress;
    final frontPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    void drawFrontSegment(double from, double to) {
      if (to <= from) return;
      canvas.drawArc(ellipse, from, to - from, false, frontPaint);
      canvas.drawArc(
        ellipse,
        from,
        to - from,
        false,
        Paint()
          ..color = const Color(0xFF92400E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    drawFrontSegment(anchorAngle, math.min(math.pi, endAngle));
    if (endAngle > math.pi * 2) {
      drawFrontSegment(math.pi * 2, math.min(math.pi * 2.5, endAngle));
    }

    final zeroPoint = _ellipsePoint(ellipse, anchorAngle);

    _paintTapeLabel(canvas, '0', zeroPoint.translate(0, -23));

    final tickCount = (10 * tapeProgress).round();
    for (var i = 0; i <= tickCount; i++) {
      final t = i / 10;
      final angle = anchorAngle + t * math.pi * 2;
      if (angle > math.pi && angle < math.pi * 2) continue;
      final point = _ellipsePoint(ellipse, angle);
      canvas.drawLine(
        point.translate(0, -8),
        point.translate(0, 8),
        Paint()
          ..color = const Color(0xFF111827)
          ..strokeWidth = 1,
      );
    }

    final freeEnd = _ellipsePoint(ellipse, endAngle);
    if (tapeProgress < .98) {
      canvas.drawCircle(freeEnd, 7, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(freeEnd, 3.5, Paint()..color = Colors.white);
    }

    if (tapeProgress >= .98) {
      _paintTapeLabel(canvas, '80cm', zeroPoint.translate(0, 25));
      canvas.drawCircle(zeroPoint, 8, Paint()..color = const Color(0xFF16A34A));
      canvas.drawCircle(zeroPoint, 4, Paint()..color = Colors.white);
    }
  }

  Offset _ellipsePoint(Rect ellipse, double angle) {
    return Offset(
      ellipse.center.dx + math.cos(angle) * ellipse.width / 2,
      ellipse.center.dy + math.sin(angle) * ellipse.height / 2,
    );
  }

  void _paintTapeLabel(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: 13,
          color: Color(0xFF92400E),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: painter.width + 14,
        height: painter.height + 8,
      ),
      const Radius.circular(999),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFFFF7ED));
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TrunkMeasurePainter oldDelegate) {
    return rotation != oldDelegate.rotation ||
        tapeProgress != oldDelegate.tapeProgress;
  }
}

class _ToolChoiceSummaryPanel extends StatefulWidget {
  const _ToolChoiceSummaryPanel();

  @override
  State<_ToolChoiceSummaryPanel> createState() =>
      _ToolChoiceSummaryPanelState();
}

class _ToolChoiceSummaryPanelState extends State<_ToolChoiceSummaryPanel> {
  bool _showNative = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '形を見て、道具を選びます。',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _SupportIconButton(
              icon: Icons.translate_rounded,
              label: 'Português',
              selected: _showNative,
              onPressed: () => setState(() => _showNative = !_showNative),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            final gap = columns == 2 ? 14.0 : 10.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _ToolChoiceChip(
                    icon: Icons.edit_rounded,
                    label: 'えんぴつ',
                    feature: '短い・まっすぐ',
                    tool: 'ものさし',
                    reason: '短いから',
                    nativeFeature: 'curto e reto',
                    nativeReason: 'porque é curto',
                    showNative: _showNative,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _ToolChoiceChip(
                    icon: Icons.credit_card_rounded,
                    label: 'カード',
                    feature: '短い・まっすぐ',
                    tool: 'ものさし',
                    reason: '短くて、はしが見やすいから',
                    nativeFeature: 'curto e reto',
                    nativeReason: 'porque é curto e dá para ver as pontas',
                    showNative: _showNative,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _ToolChoiceChip(
                    icon: Icons.meeting_room_rounded,
                    label: 'ろうか',
                    feature: '長い',
                    tool: 'まきじゃく',
                    reason: '長いから',
                    nativeFeature: 'comprido',
                    nativeReason: 'porque é comprido',
                    showNative: _showNative,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _ToolChoiceChip(
                    icon: Icons.park_rounded,
                    label: '木のみきのまわり',
                    feature: 'まるい',
                    tool: 'まきじゃく',
                    reason: 'まるいから',
                    nativeFeature: 'redondo',
                    nativeReason: 'porque é redondo',
                    showNative: _showNative,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ToolChoiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String feature;
  final String tool;
  final String reason;
  final String nativeFeature;
  final String nativeReason;
  final bool showNative;

  const _ToolChoiceChip({
    required this.icon,
    required this.label,
    required this.feature,
    required this.tool,
    required this.reason,
    required this.nativeFeature,
    required this.nativeReason,
    required this.showNative,
  });

  @override
  Widget build(BuildContext context) {
    final featureText = showNative ? nativeFeature : feature;
    final reasonText = showNative ? nativeReason : reason;
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ToolPill(text: tool),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ToolChoiceNote(
                  label: showNative ? 'forma' : '形',
                  text: featureText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToolChoiceNote(
                  label: showNative ? 'motivo' : '理由',
                  text: reasonText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolPill extends StatelessWidget {
  final String text;

  const _ToolPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ToolChoiceNote extends StatelessWidget {
  final String label;
  final String text;

  const _ToolChoiceNote({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _KilometerLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _KilometerLearn({required this.selectedLanguage});

  @override
  State<_KilometerLearn> createState() => _KilometerLearnState();
}

class _KilometerLearnState extends State<_KilometerLearn> {
  int _page = 0;
  int _routeStep = 0;
  bool _showNative = false;

  static const _lastPage = 1;

  int get _currentPage => _page.clamp(0, _lastPage).toInt();

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: 'キロメートル',
      text: _pageLines.first.japanese,
    );
  }

  List<SupportLine> get _pageLines {
    return switch (_currentPage) {
      0 => const [
        SupportLine(
          japanese: '家から公園まで、道にそって歩いてみよう。',
          ruby: '{家|いえ}から{公園|こうえん}まで、{道|みち}にそって{歩|ある}いてみよう。',
          native: {
            AppLanguage.portuguese:
                'Vamos caminhar pelo caminho da casa até o parque.',
            AppLanguage.tagalog:
                'Maglakad tayo sa daan mula sa bahay hanggang parke.',
            AppLanguage.vietnamese:
                'Hãy đi theo đường từ nhà đến công viên.',
          },
        ),
      ],
      1 => const [
        SupportLine(
          japanese: '1kmは1000mです。kmはキロメートルといいます。長い道のりはkmで表すとわかりやすいです。',
          ruby:
              '1kmは1000mです。kmは{キロメートル|きろめーとる}といいます。{長|なが}い{道|みち}のりはkmで{表|あらわ}すとわかりやすいです。',
          native: {
            AppLanguage.portuguese:
                '1 km são 1000 m. km se lê quilômetro. Caminhos longos ficam mais fáceis de entender em km.',
            AppLanguage.tagalog:
                '1 km ay 1000 m. Binabasa ang km na kilometro. Mas madaling intindihin ang mahahabang daan sa km.',
            AppLanguage.vietnamese:
                '1 km bằng 1000 m. km đọc là kilômét. Đường dài dễ hiểu hơn khi dùng km.',
          },
        ),
      ],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _currentPage;
    return _RemainderLearnShell(
      icon: Icons.map_rounded,
      title: '学校から町へ出かけよう',
      titleRuby: '{学校|がっこう}から{町|まち}へ{出|で}かけよう',
      titleVocabularyEntries: _lengthVocabularyEntries,
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () => setState(() => _showNative = !_showNative),
      onAudio: _speak,
      page: currentPage,
      lastPage: _lastPage,
      onPrevious: () {
        if (currentPage == 0) return;
        setState(() => _page = currentPage - 1);
      },
      onNext: () {
        if (currentPage == _lastPage) return;
        setState(() {
          if (currentPage == 0) _routeStep = 0;
          _page = currentPage + 1;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SupportedTextLines(
            lines: _pageLines,
            language: widget.selectedLanguage,
            showNative: _showNative,
            vocabularyEntries: _lengthVocabularyEntries,
            enableLearningSupport: true,
          ),
          const SizedBox(height: 18),
          switch (currentPage) {
            0 => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InlineExplanationSupport(
                  line: const SupportLine(
                    japanese: 'ボタンをおして、道にそって進んでみよう。',
                    ruby: 'ボタンをおして、{道|みち}にそって{進|すす}んでみよう。',
                    native: {
                      AppLanguage.portuguese:
                          'Aperte o botao e vamos seguir pelo caminho.',
                      AppLanguage.tagalog:
                          'Pindutin ang pindutan at sundan natin ang daan.',
                      AppLanguage.vietnamese:
                          'Hay bam nut va di theo con duong nhe.',
                    },
                  ),
                  language: widget.selectedLanguage,
                  vocabularyEntries: _lengthVocabularyEntries,
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
                const SizedBox(height: 18),
                _DistanceRoutePanel(
                  step: _routeStep,
                  onAdvance: () => setState(() {
                    _routeStep = (_routeStep + 1).clamp(0, 3);
                  }),
                ),
              ],
            ),
            1 => _KilometerConversionPanel(language: widget.selectedLanguage),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _DistanceRoutePanel extends StatelessWidget {
  final int step;
  final VoidCallback onAdvance;

  const _DistanceRoutePanel({required this.step, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final total = [0, 300, 700, 1000][step];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SimpleDistanceMap(highlightedSegments: step),
        if (step >= 3) ...[
          const SizedBox(height: 14),
          const Text(
            '公園につきました',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '進んだ道のり：$total m',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
        if (step >= 3) ...[
          const SizedBox(height: 10),
          const _DistanceConceptBox(),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: step >= 3 ? null : onAdvance,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            disabledBackgroundColor: const Color(0xFFE5E7EB),
          ),
          child: Text(step >= 3 ? '1kmになりました' : 'つぎの道を進む'),
        ),
      ],
    );
  }
}

class _DistanceConceptBox extends StatefulWidget {
  const _DistanceConceptBox();

  @override
  State<_DistanceConceptBox> createState() => _DistanceConceptBoxState();
}

class _DistanceConceptBoxState extends State<_DistanceConceptBox> {
  bool _showNative = false;

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: '道のりときょり',
      text: '道のりは、道にそってはかった長さです。きょりは、まっすぐにはかった長さです。',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 24,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: RubyText(
                    text: '{道|みち}のりときょり',
                    enableLearningSupport: true,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      color: Color(0xFF064E3B),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _SupportIconButton(
                icon: Icons.translate_rounded,
                label: 'Português',
                selected: _showNative,
                onPressed: () => setState(() => _showNative = !_showNative),
              ),
              const SizedBox(width: 8),
              _SupportIconButton(
                icon: Icons.volume_up_rounded,
                label: '音声',
                onPressed: _speak,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.only(left: 33),
            child: _showNative
                ? const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'O '),
                        TextSpan(
                          text: 'caminho',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' é o comprimento medido seguindo a estrada. A ',
                        ),
                        TextSpan(
                          text: 'distância',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' é o comprimento medido em linha reta.',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.interface,
                      color: Color(0xFF064E3B),
                      fontSize: 17,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const _DistanceConceptJapaneseText(),
          ),
        ],
      ),
    );
  }
}

class _DistanceConceptJapaneseText extends StatelessWidget {
  const _DistanceConceptJapaneseText();

  static const _bodyStyle = TextStyle(
    fontFamily: AppFonts.interface,
    color: Color(0xFF064E3B),
    fontSize: 17,
    height: 1.55,
    fontWeight: FontWeight.w600,
  );
  static const _routeStyle = TextStyle(
    fontFamily: AppFonts.interface,
    color: Color(0xFF2563EB),
    fontSize: 17,
    height: 1.55,
    fontWeight: FontWeight.w800,
  );
  static const _distanceStyle = TextStyle(
    fontFamily: AppFonts.interface,
    color: Color(0xFFEF4444),
    fontSize: 17,
    height: 1.55,
    fontWeight: FontWeight.w800,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RubyText(
              text: '{道|みち}にそってはかった{長|なが}さを「',
              style: _bodyStyle,
              enableLearningSupport: true,
            ),
            RubyText(
              text: '{道|みち}のり',
              style: _routeStyle,
              enableLearningSupport: true,
            ),
            RubyText(
              text: '」といいます。',
              style: _bodyStyle,
              enableLearningSupport: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RubyText(
              text: 'まっすぐにはかった{長|なが}さを「',
              style: _bodyStyle,
              enableLearningSupport: true,
            ),
            RubyText(
              text: 'きょり',
              style: _distanceStyle,
              enableLearningSupport: true,
            ),
            RubyText(
              text: '」といいます。',
              style: _bodyStyle,
              enableLearningSupport: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _SimpleDistanceMap extends StatelessWidget {
  final int highlightedSegments;

  const _SimpleDistanceMap({required this.highlightedSegments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: CustomPaint(
        painter: _SimpleDistanceMapPainter(highlightedSegments),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SimpleDistanceMapPainter extends CustomPainter {
  final int highlightedSegments;

  const _SimpleDistanceMapPainter(this.highlightedSegments);

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * .13, size.height * .70),
      Offset(size.width * .36, size.height * .42),
      Offset(size.width * .61, size.height * .58),
      Offset(size.width * .86, size.height * .28),
    ];
    final labels = ['家', '学校', 'コンビニ', '公園'];
    final segments = ['300m', '400m', '300m'];
    final grey = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final blue = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final distancePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (highlightedSegments >= 3) {
      _drawDashedLine(canvas, points.first, points.last, distancePaint);
      _paintText(
        canvas,
        'きょり 約800m',
        (points.first + points.last) / 2 + const Offset(0, -54),
        14,
        const Color(0xFFEF4444),
      );
    }

    for (var i = 0; i < points.length - 1; i++) {
      final path = _segmentPath(points, i);
      canvas.drawPath(path, i < highlightedSegments ? blue : grey);
      _paintText(
        canvas,
        segments[i],
        _segmentLabelPoint(points, i),
        13,
        const Color(0xFF334155),
      );
    }
    for (var i = 0; i < points.length; i++) {
      _drawPlaceIcon(canvas, points[i], i);
      _paintText(
        canvas,
        labels[i],
        points[i] + const Offset(0, 34),
        14,
        const Color(0xFF111827),
      );
    }
    if (highlightedSegments >= 3) {
      _paintText(
        canvas,
        '道のり 1000m',
        Offset(size.width * .5, size.height - 14),
        16,
        const Color(0xFF2563EB),
      );
    }
  }

  Path _segmentPath(List<Offset> points, int index) {
    final start = points[index];
    final end = points[index + 1];
    final dx = end.dx - start.dx;
    final curve = index.isEven ? -34.0 : 30.0;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + dx * .28,
        start.dy + curve,
        start.dx + dx * .72,
        end.dy - curve,
        end.dx,
        end.dy,
      );
  }

  Offset _segmentLabelPoint(List<Offset> points, int index) {
    final midpoint = (points[index] + points[index + 1]) / 2;
    return midpoint + Offset(0, index.isEven ? -34 : 30);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final vector = end - start;
    final distance = vector.distance;
    final direction = vector / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final dashEnd = math.min(drawn + 12, distance);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * dashEnd,
        paint,
      );
      drawn += 22;
    }
  }

  void _drawPlaceIcon(Canvas canvas, Offset center, int index) {
    canvas.drawCircle(center, 19, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      19,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    switch (index) {
      case 0:
        _drawHouse(canvas, center);
        return;
      case 1:
        _drawSchool(canvas, center);
        return;
      case 2:
        _drawStore(canvas, center);
        return;
      default:
        _drawPark(canvas, center);
        return;
    }
  }

  void _drawHouse(Canvas canvas, Offset center) {
    final roof = Path()
      ..moveTo(center.dx - 11, center.dy - 1)
      ..lineTo(center.dx, center.dy - 11)
      ..lineTo(center.dx + 11, center.dy - 1)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFEF4444));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 6), width: 18, height: 16),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFF59E0B),
    );
  }

  void _drawSchool(Canvas canvas, Offset center) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 3), width: 24, height: 22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF60A5FA),
    );
    canvas.drawRect(
      Rect.fromCenter(center: center.translate(0, 10), width: 5, height: 8),
      Paint()..color = Colors.white,
    );
    for (final dx in [-7.0, 0.0, 7.0]) {
      canvas.drawCircle(
        center.translate(dx, 0),
        2.2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawStore(Canvas canvas, Offset center) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 4), width: 24, height: 18),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 12, center.dy - 7, 24, 6),
      Paint()..color = const Color(0xFF22C55E),
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 12, center.dy - 1, 24, 4),
      Paint()..color = const Color(0xFFF97316),
    );
  }

  void _drawPark(Canvas canvas, Offset center) {
    canvas.drawRect(
      Rect.fromCenter(center: center.translate(0, 8), width: 5, height: 14),
      Paint()..color = const Color(0xFF92400E),
    );
    canvas.drawCircle(
      center.translate(-5, -1),
      8,
      Paint()..color = const Color(0xFF22C55E),
    );
    canvas.drawCircle(
      center.translate(5, -2),
      8,
      Paint()..color = const Color(0xFF16A34A),
    );
    canvas.drawCircle(
      center.translate(0, -8),
      8,
      Paint()..color = const Color(0xFF86EFAC),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleDistanceMapPainter oldDelegate) {
    return highlightedSegments != oldDelegate.highlightedSegments;
  }
}

class _KilometerConversionPanel extends StatelessWidget {
  final AppLanguage language;

  const _KilometerConversionPanel({required this.language});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '1km',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '=',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Text(
              '1000m',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 560;
            final cards = [
              _KilometerExampleCard(
                placeRuby: '{図書館|としょかん}',
                meters: '1500m',
                kilometers: '1km500m',
                language: language,
              ),
              _KilometerExampleCard(
                placeRuby: '{駅|えき}',
                meters: '2000m',
                kilometers: '2km',
                language: language,
              ),
            ];
            if (!useRow) {
              return Column(
                children: [cards[0], const SizedBox(height: 12), cards[1]],
              );
            }
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KilometerExampleCard extends StatelessWidget {
  final String placeRuby;
  final String meters;
  final String kilometers;
  final AppLanguage language;

  const _KilometerExampleCard({
    required this.placeRuby,
    required this.meters,
    required this.kilometers,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RubyText(
            text: placeRuby,
            language: language,
            vocabularyEntries: _lengthVocabularyEntries,
            enableLearningSupport: true,
            style: const TextStyle(
              fontFamily: AppFonts.interface,
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                meters,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kilometers,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      color: Color(0xFF2563EB),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftResultLine extends StatelessWidget {
  final String text;
  final bool good;

  const _SoftResultLine({required String text, bool good = false})
      : text = text,
        good = good;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: good ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: good ? const Color(0xFF047857) : const Color(0xFF1E3A8A),
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

final _lengthVocabularyEntries = [
  VocabularyEntry(
    term: '長さ',
    reading: 'ながさ',
    simpleJapanese: 'もののはしからはしまでの大きさ。',
    translations: nativeText(
      portuguese: 'comprimento',
      tagalog: 'haba',
      vietnamese: 'độ dài',
    ),
    exampleSentence: 'つくえの長さをはかります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'はかる',
    surfaces: const ['はかる', 'はかります', 'はかりましょう', 'はかって'],
    reading: 'はかる',
    simpleJapanese: '長さなどを調べること。',
    translations: nativeText(
      portuguese: 'medir',
      tagalog: 'sukatin',
      vietnamese: 'đo',
    ),
    exampleSentence: 'まきじゃくで長さをはかります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '目もり',
    reading: 'めもり',
    simpleJapanese: 'ものさしについている小さなしるし。',
    translations: nativeText(
      portuguese: 'marca / escala',
      tagalog: 'marka',
      vietnamese: 'vạch chia',
    ),
    exampleSentence: '目もりを読みます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '道のり',
    reading: 'みちのり',
    simpleJapanese: '実際に通る道の長さ。',
    translations: nativeText(
      portuguese: 'caminho / percurso',
      tagalog: 'daan / ruta',
      vietnamese: 'quãng đường',
    ),
    exampleSentence: '学校から公園までの道のりを考えます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'キロメートル',
    reading: 'きろめーとる',
    simpleJapanese: '長い長さを表す単位。1kmは1000m。',
    translations: nativeText(
      portuguese: 'quilômetro',
      tagalog: 'kilometro',
      vietnamese: 'kilômét',
    ),
    exampleSentence: '1000mは1kmです。',
    category: 'math_language',
  ),
];

class _MultiplicationDivisionLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _MultiplicationDivisionLearn({required this.selectedLanguage});

  @override
  State<_MultiplicationDivisionLearn> createState() =>
      _MultiplicationDivisionLearnState();
}

class _MultiplicationDivisionLearnState
    extends State<_MultiplicationDivisionLearn> {
  int _page = 0;
  bool _showNative = false;

  static const int _lastPage = 1;

  void _speak(String label, String text) {
    LearningAudio.speakJapanese(context, label: label, text: text);
  }

  void _previous() {
    if (_page == 0) return;
    setState(() {
      _page--;
    });
  }

  void _next() {
    if (_page == _lastPage) return;
    setState(() {
      _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _pageTitle,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 24,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _IconSupportActions(
                language: widget.selectedLanguage,
                showNative: _showNative,
                translateLabel: '翻訳',
                audioLabel: '音声',
                onToggleNative: () {
                  setState(() {
                    _showNative = !_showNative;
                  });
                },
                onAudio: () => _speak(_pageTitle, _plainJapanese),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_page), child: _buildPage()),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              OutlinedButton(
                onPressed: _page == 0 ? null : _previous,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('もどる'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _page == _lastPage ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('つぎ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _pageTitle {
    return switch (_page) {
      0 => 'かけ算を使って、わり算の答えを見つけよう',
      _ => '同じ数がつながっているね',
    };
  }

  String get _plainJapanese {
    return switch (_page) {
      0 => 'かけ算を使って、わり算の答えを見つけよう。わり算とかけ算には、どんなつながりがあるかな。',
      _ => '同じ3つの数を使って、わり算とかけ算の式を作ることができます。',
    };
  }

  Widget _buildPage() {
    return switch (_page) {
      0 => _buildAimPage(),
      _ => _buildEquationConnectionPage(),
    };
  }

  Widget _buildAimPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: '12このクッキーを、3人に同じ数ずつ分けてみよう。',
              ruby: '12このクッキーを、3{人|にん}に{同じ数ずつ|おなじ かずずつ}{分けてみよう|わけてみよう}。',
              native: {
                AppLanguage.portuguese:
                    'Vamos dividir 12 biscoitos igualmente entre 3 pessoas.',
                AppLanguage.tagalog:
                    'Hatiin natin ang 12 biskwit nang pantay sa 3 tao.',
                AppLanguage.vietnamese:
                    'Hãy chia đều 12 cái bánh quy cho 3 người.',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        _InteractiveCookieShare(language: widget.selectedLanguage),
      ],
    );
  }

  Widget _buildEquationConnectionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: '同じ3つの数を使って、わり算とかけ算の式を作ることができます。',
              ruby:
                  '{同じ|おなじ}3つの{数|かず}を{使って|つかって}、{わり算|わりざん}と{かけ算|かけざん}の{式|しき}を{作る|つくる}ことができます。',
              native: {
                AppLanguage.portuguese:
                    'Com os mesmos três números, podemos fazer uma conta de divisão e uma de multiplicação.',
                AppLanguage.tagalog:
                    'Gamit ang parehong tatlong numero, makakagawa tayo ng dibisyon at multiplikasyon.',
                AppLanguage.vietnamese:
                    'Với cùng ba số, ta có thể viết phép chia và phép nhân.',
              },
            ),
            SupportLine(
              japanese: 'わり算の答えは、かけ算を使って見つけられます。',
              ruby:
                  '{わり算|わりざん}の{答え|こたえ}は、{かけ算|かけざん}を{使って|つかって}{見つけられます|みつけられます}。',
              native: {
                AppLanguage.portuguese:
                    'A resposta da divisão pode ser encontrada usando a multiplicação.',
                AppLanguage.tagalog:
                    'Ang sagot sa dibisyon ay mahanap gamit ang multiplikasyon.',
                AppLanguage.vietnamese:
                    'Có thể tìm đáp án phép chia nhờ phép nhân.',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        _EquationPairPanel(language: widget.selectedLanguage),
      ],
    );
  }
}

class _RemainderDivisionLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _RemainderDivisionLearn({required this.selectedLanguage});

  @override
  State<_RemainderDivisionLearn> createState() =>
      _RemainderDivisionLearnState();
}

class _RemainderDivisionLearnState extends State<_RemainderDivisionLearn> {
  int _page = 0;
  bool _showNative = false;

  static const _lastPage = 3;

  void _previous() {
    if (_page == 0) return;
    setState(() => _page--);
  }

  void _next() {
    if (_page == _lastPage) return;
    setState(() => _page++);
  }

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: _pageTitle,
      text: _pageLines.map((line) => line.japanese).join(' '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RemainderLearnShell(
      icon: Icons.more_horiz_rounded,
      title: _pageTitle,
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () => setState(() => _showNative = !_showNative),
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: _previous,
      onNext: _next,
      child: _buildPage(),
    );
  }

  String get _pageTitle {
    return switch (_page) {
      0 => 'あまりのあるわり算',
      1 => '式で書いてみよう',
      2 => '九九でもたしかめられるね',
      _ => 'あまりは、わる数より小さい',
    };
  }

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: 'いちごが7こあります。',
          ruby: 'いちごが7こあります。',
          native: {
            AppLanguage.portuguese: 'Há 7 morangos.',
            AppLanguage.tagalog: 'May 7 na strawberry.',
            AppLanguage.vietnamese: 'Có 7 quả dâu.',
          }
        ),
        SupportLine(
          japanese: '3人で同じ数ずつ分けると、1人分は2こで、1こ残ります。',
          ruby:
              '3{人|にん}で{同|おな}じ{数|かず}ずつ{分|わ}けると、{1人|ひとり}{分|ぶん}は2こで、1こ{残|のこ}ります。',
          native: {
            AppLanguage.portuguese:
                'Dividindo igualmente entre 3 pessoas, cada pessoa recebe 2 e sobra 1.',
            AppLanguage.tagalog:
                'Kapag hinati nang pantay sa 3 tao, 2 ang sa bawat isa at 1 ang natira.',
            AppLanguage.vietnamese:
                'Chia đều cho 3 người thì mỗi người được 2, còn dư 1.',
          },
        ),
      ],
      // 図から数を選ぶ前に答えを見せない。
      1 => const [],
      // 九九を選ぶ前に、答えとなる段やあまりを見せない。
      2 => const [],
      _ => const [
        SupportLine(
          japanese: '3人で分けると、あまりは0、1、2のどれかです。',
          ruby: '3{人|にん}で{分|わ}けると、あまりは0、1、2のどれかです。',
          native: {
            AppLanguage.portuguese:
                'Ao dividir entre 3 pessoas, o resto pode ser 0, 1 ou 2.',
            AppLanguage.tagalog:
                'Kapag hinati sa 3 tao, ang sobra ay maaaring 0, 1, o 2.',
            AppLanguage.vietnamese:
                'Khi chia cho 3 người, số dư có thể là 0, 1 hoặc 2.',
          },
        ),
        SupportLine(
          japanese: 'あまりが3こになったら、もう1人分を作れます。',
          ruby: 'あまりが3こになったら、もう{1人|ひとり}{分|ぶん}を{作|つく}れます。',
          native: {
            AppLanguage.portuguese:
                'Se sobrassem 3, daria para formar mais uma parte.',
            AppLanguage.tagalog:
                'Kung 3 ang natira, makakagawa pa ng isa pang bahagi.',
            AppLanguage.vietnamese:
                'Nếu dư 3 thì còn làm thêm được một phần nữa.',
          },
        ),
      ],
    };
  }

  Widget _buildPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SupportedTextLines(
          lines: _pageLines,
          language: widget.selectedLanguage,
          showNative: _showNative,
          vocabularyEntries: _remainderLearnVocabulary,
          enableLearningSupport: true,
        ),
        const SizedBox(height: 18),
        switch (_page) {
          0 => _InteractiveRemainderShare(language: widget.selectedLanguage),
          1 => _RemainderEquationBuilder(language: widget.selectedLanguage),
          2 => _RemainderTimesTableFinder(language: widget.selectedLanguage),
          _ => _RemainderGrowthExplorer(language: widget.selectedLanguage),
        },
      ],
    );
  }
}

class _RemainderContextLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _RemainderContextLearn({required this.selectedLanguage});

  @override
  State<_RemainderContextLearn> createState() => _RemainderContextLearnState();
}

class _RemainderContextLearnState extends State<_RemainderContextLearn> {
  int _page = 0;
  bool _showNative = false;

  static const _lastPage = 2;

  void _previous() {
    if (_page == 0) return;
    setState(() => _page--);
  }

  void _next() {
    if (_page == _lastPage) return;
    setState(() => _page++);
  }

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: _pageTitle,
      text: _pageLines.map((line) => line.japanese).join(' '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RemainderLearnShell(
      icon: Icons.event_seat_rounded,
      title: _pageTitle,
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () => setState(() => _showNative = !_showNative),
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: _previous,
      onNext: _next,
      child: _buildPage(),
    );
  }

  String get _pageTitle {
    return switch (_page) {
      0 => 'あまりが出たら、場面を見よう',
      1 => 'もう1台いるね',
      _ => 'まとめ',
    };
  }

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: '4人がけの長いすがあります。',
          ruby: '4{人|にん}がけの{長|なが}いすがあります。',
          native: {
            AppLanguage.portuguese: 'Há bancos para 4 pessoas.',
            AppLanguage.tagalog: 'May bangko para sa 4 na tao.',
            AppLanguage.vietnamese: 'Có ghế dài cho 4 người.',
          }
        ),
        SupportLine(
          japanese: '9人がすわるには、長いすは何台いるかな？',
          ruby: '9{人|にん}がすわるには、{長|なが}いすは{何台|なんだい}いるかな？',
          native: {
            AppLanguage.portuguese:
                'Para 9 pessoas se sentarem, quantos bancos são necessários?',
            AppLanguage.tagalog:
                'Ilang bangko ang kailangan para makaupo ang 9 na tao?',
            AppLanguage.vietnamese:
                'Cần bao nhiêu ghế để 9 người ngồi?',
          },
        ),
      ],
      1 => const [
        SupportLine(
          japanese: 'あまった1人もすわるので、もう1台いります。',
          ruby: 'あまった1{人|ひとり}もすわるので、もう1{台|だい}いります。',
          native: {
            AppLanguage.portuguese:
                'A pessoa que sobrou também precisa se sentar, então precisamos de mais 1 banco.',
            AppLanguage.tagalog:
                'Kailangan ding umupo ang natirang tao, kaya kailangan pa ng 1 bangko.',
            AppLanguage.vietnamese:
                'Người còn lại cũng cần ngồi, nên cần thêm 1 ghế.',
          },
        ),
      ],
      _ => const [
        SupportLine(
          japanese: 'あまりが出たら、問題の場面に戻って考えます。',
          ruby: 'あまりが{出|で}たら、{問題|もんだい}の{場面|ばめん}に{戻|もど}って{考|かんが}えます。',
          native: {
            AppLanguage.portuguese:
                'Quando aparece resto, voltamos à situação do problema e pensamos.',
            AppLanguage.tagalog:
                'Kapag may sobra, bumalik tayo sa sitwasyon ng problema at mag-isip.',
            AppLanguage.vietnamese:
                'Khi có số dư, ta quay lại tình huống bài toán rồi suy nghĩ.',
          },
        ),
        SupportLine(
          japanese: '人がすわる問題では、あまった人のために1つ増やすことがあります。',
          ruby: '{人|ひと}がすわる{問題|もんだい}では、あまった{人|ひと}のために1つ{増|ふ}やすことがあります。',
          native: {
            AppLanguage.portuguese:
                'Em problemas com pessoas sentando, às vezes aumentamos 1 para quem sobrou.',
            AppLanguage.tagalog:
                'Sa problemang umuupo ang tao, minsan dagdag tayo ng 1 para sa natira.',
            AppLanguage.vietnamese:
                'Ở bài toán chỗ ngồi, đôi khi ta cộng thêm 1 cho người còn lại.',
          },
        ),
      ],
    };
  }

  Widget _buildPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SupportedTextLines(
          lines: _pageLines,
          language: widget.selectedLanguage,
          showNative: _showNative,
          vocabularyEntries: _remainderContextVocabulary,
          enableLearningSupport: true,
        ),
        const SizedBox(height: 18),
        switch (_page) {
          0 => _BenchRemainderDiagram(
            benchCount: 2,
            showWaiting: true,
            selectedLanguage: widget.selectedLanguage,
          ),
          1 => _BenchRemainderDiagram(
            benchCount: 3,
            showWaiting: false,
            selectedLanguage: widget.selectedLanguage,
          ),
          _ => _RemainderContextSummaryPanel(
            selectedLanguage: widget.selectedLanguage,
          ),
        },
      ],
    );
  }
}

class _WeightGramKgLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _WeightGramKgLearn({required this.selectedLanguage});

  @override
  State<_WeightGramKgLearn> createState() => _WeightGramKgLearnState();
}

class _WeightGramKgLearnState extends State<_WeightGramKgLearn> {
  int _page = 0;
  bool _showNative = false;
  bool _showComparisonInstructionNative = false;
  bool _showComparisonResultNative = false;
  bool _showScaleInstructionNative = false;
  bool _showScaleResultNative = false;
  bool _showThousandInstructionNative = false;
  bool _showThousandResultNative = false;
  bool _appleOnBalance = false;
  bool _pencilOnBalance = false;
  bool _appleOnScale = false;
  int _weightCount = 0;

  static const _lastPage = 3;

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: 'りんごとえんぴつ、どちらが重いかな。',
          ruby: 'りんごとえんぴつ、どちらが{重|おも}いかな。',
          native: {
            AppLanguage.portuguese:
                'A maçã e o lápis: qual você acha que é mais pesado?',
            AppLanguage.tagalog:
                'Mansanas at lapis: alin sa palagay mo ang mas mabigat?',
            AppLanguage.vietnamese:
                'Quả táo và bút chì: bạn nghĩ cái nào nặng hơn?',
          },
        ),
      ],
      1 => const [
        SupportLine(
          japanese: 'りんごの重さをはかってみよう。',
          ruby: 'りんごの{重|おも}さをはかってみよう。',
          native: {
            AppLanguage.portuguese: 'Vamos medir o peso da maçã.',
            AppLanguage.tagalog: 'Sukatin natin ang timbang ng mansanas.',
            AppLanguage.vietnamese: 'Hãy đo khối lượng quả táo.',
          }
        ),
      ],
      2 => const [
        SupportLine(
          japanese: '100gのおもりを10こ使うと、何gになるかな。',
          ruby: '100gのおもりを10こ{使|つか}うと、{何|なん}gになるかな。',
          native: {
            AppLanguage.portuguese:
                'Se usarmos 10 pesos de 100 g, quantos gramas teremos?',
            AppLanguage.tagalog:
                'Kung gagamit tayo ng 10 pabigat na 100 g, ilang g ito?',
            AppLanguage.vietnamese:
                'Nếu dùng 10 quả cân 100 g thì được bao nhiêu g?',
          },
        ),
      ],
      _ => const [
        SupportLine(
          japanese: '少し重いものは、kgとgを合わせて表すことがあります。',
          ruby: '{少|すこ}し{重|おも}いものは、kgとgを{合|あ}わせて{表|あらわ}すことがあります。',
          native: {
            AppLanguage.portuguese:
                'Para coisas um pouco pesadas, podemos usar kg e g juntos.',
            AppLanguage.tagalog:
                'Para sa medyo mabibigat, puwedeng gamitin nang magkasama ang kg at g.',
            AppLanguage.vietnamese:
                'Với đồ hơi nặng, có thể dùng cả kg và g.',
          },
        ),
      ],
    };
  }

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: '重さ',
      text: _pageLines.map((line) => line.japanese).join(' '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RemainderLearnShell(
      icon: Icons.monitor_weight_rounded,
      title: '重さをはかってみよう',
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () => setState(() => _showNative = !_showNative),
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: () => setState(() => _page = math.max(0, _page - 1)),
      onNext: () => setState(() => _page = math.min(_lastPage, _page + 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SupportedTextLines(
            lines: _pageLines,
            language: widget.selectedLanguage,
            showNative: _showNative,
            vocabularyEntries: _weightVocabularyEntries,
            enableLearningSupport: true,
          ),
          const SizedBox(height: 18),
          switch (_page) {
            0 => _WeightComparePanel(
              selectedLanguage: widget.selectedLanguage,
              appleOnBalance: _appleOnBalance,
              pencilOnBalance: _pencilOnBalance,
              showInstructionNative: _showComparisonInstructionNative,
              onToggleInstructionNative: () => setState(
                () => _showComparisonInstructionNative =
                    !_showComparisonInstructionNative,
              ),
              showResultNative: _showComparisonResultNative,
              onToggleResultNative: () => setState(
                () =>
                    _showComparisonResultNative = !_showComparisonResultNative,
              ),
              onPlaceApple: () => setState(() => _appleOnBalance = true),
              onPlacePencil: () => setState(() => _pencilOnBalance = true),
              onReset: () => setState(() {
                _appleOnBalance = false;
                _pencilOnBalance = false;
              }),
            ),
            1 => _WeightScaleDragPanel(
              selectedLanguage: widget.selectedLanguage,
              appleOnScale: _appleOnScale,
              showInstructionNative: _showScaleInstructionNative,
              onToggleInstructionNative: () => setState(
                () =>
                    _showScaleInstructionNative = !_showScaleInstructionNative,
              ),
              showResultNative: _showScaleResultNative,
              onToggleResultNative: () => setState(
                () => _showScaleResultNative = !_showScaleResultNative,
              ),
              onAccept: () => setState(() => _appleOnScale = true),
              onReset: () => setState(() => _appleOnScale = false),
            ),
            2 => _WeightThousandPanel(
              selectedLanguage: widget.selectedLanguage,
              count: _weightCount,
              showInstructionNative: _showThousandInstructionNative,
              onToggleInstructionNative: () => setState(
                () => _showThousandInstructionNative =
                    !_showThousandInstructionNative,
              ),
              showResultNative: _showThousandResultNative,
              onToggleResultNative: () => setState(
                () => _showThousandResultNative = !_showThousandResultNative,
              ),
              onAdd: () => setState(() {
                if (_weightCount < 10) _weightCount++;
              }),
              onReset: () => setState(() => _weightCount = 0),
            ),
            _ => const _WeightKgGramPanel(),
          },
        ],
      ),
    );
  }
}

enum _WeightObjectKind { apple, pencil }

class _WeightComparePanel extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final bool appleOnBalance;
  final bool pencilOnBalance;
  final bool showInstructionNative;
  final VoidCallback onToggleInstructionNative;
  final bool showResultNative;
  final VoidCallback onToggleResultNative;
  final VoidCallback onPlaceApple;
  final VoidCallback onPlacePencil;
  final VoidCallback onReset;

  const _WeightComparePanel({
    required this.selectedLanguage,
    required this.appleOnBalance,
    required this.pencilOnBalance,
    required this.showInstructionNative,
    required this.onToggleInstructionNative,
    required this.showResultNative,
    required this.onToggleResultNative,
    required this.onPlaceApple,
    required this.onPlacePencil,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final compared = appleOnBalance && pencilOnBalance;
    return Column(
      children: [
        _SupportedInstruction(
          line: const SupportLine(
            japanese: 'りんごとえんぴつを天びんにのせてみよう。',
            ruby: 'りんごとえんぴつを{天びん|てんびん}にのせてみよう。',
            native: {
              AppLanguage.portuguese:
                  'Vamos colocar a maçã e o lápis na balança de dois pratos.',
              AppLanguage.tagalog:
                  'Ilagay natin ang mansanas at lapis sa timbangan.',
              AppLanguage.vietnamese: 'Hãy đặt quả táo và bút chì lên cân đĩa.',
            },
          ),
          language: selectedLanguage,
          showNative: showInstructionNative,
          onToggleNative: onToggleInstructionNative,
          vocabularyEntries: _weightVocabularyEntries,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 620;
            final cards = [
              _WeightObjectButton(
                label: 'りんご',
                kind: _WeightObjectKind.apple,
                selected: appleOnBalance,
                onTap: onPlaceApple,
              ),
              _WeightObjectButton(
                label: 'えんぴつ',
                kind: _WeightObjectKind.pencil,
                selected: pencilOnBalance,
                onTap: onPlacePencil,
              ),
            ];
            if (!isWide) {
              return Column(
                children: [cards[0], const SizedBox(height: 12), cards[1]],
              );
            }
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        DragTarget<_WeightObjectKind>(
          onAcceptWithDetails: (details) {
            if (details.data == _WeightObjectKind.apple) {
              onPlaceApple();
            } else {
              onPlacePencil();
            }
          },
          builder: (context, candidates, _) {
            final isHovering = candidates.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: _BalancePainter(
                  appleOnBalance: appleOnBalance,
                  pencilOnBalance: pencilOnBalance,
                ),
              ),
            );
          },
        ),
        if (compared) ...[
          const SizedBox(height: 12),
          _WeightSupportedResultBox(
            title: 'りんごの方が重い',
            nativeTitle: const {
              AppLanguage.portuguese: 'A maçã é mais pesada.',
              AppLanguage.tagalog: 'Mas mabigat ang mansanas.',
              AppLanguage.vietnamese: 'Quả táo nặng hơn.',
            },
            explanation: const SupportLine(
              japanese:
                  '天びんを見ると、りんごの方がえんぴつよりも下がっています。下がった方が重いので、りんごの方が重いと分かります。ものには重さがあります。',
              ruby:
                  '{天びん|てんびん}を{見|み}ると、りんごの{方|ほう}がえんぴつよりも{下|さ}がっています。{下|さ}がった{方|ほう}が{重|おも}いので、りんごの{方|ほう}が{重|おも}いと{分|わ}かります。ものには{重|おも}さがあります。',
              native: {
                AppLanguage.portuguese:
                    'Na balança, o lado da maçã ficou mais baixo. O lado que desce é o mais pesado. Por isso, a maçã é mais pesada que o lápis. Os objetos têm peso.',
                AppLanguage.tagalog:
                    'Sa timbangan, mas mababa ang panig ng mansanas. Mas mabigat ang panig na bumababa. Kaya mas mabigat ang mansanas kaysa lapis. May bigat ang mga bagay.',
                AppLanguage.vietnamese:
                    'Trên cân đĩa, phía quả táo thấp hơn. Bên hạ xuống là bên nặng hơn. Vì vậy quả táo nặng hơn bút chì. Mọi vật đều có khối lượng.',
              },
            ),
            selectedLanguage: selectedLanguage,
            showNative: showResultNative,
            onToggleNative: onToggleResultNative,
            vocabularyEntries: _weightVocabularyEntries,
            audioLabel: '重さの説明を聞く',
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _LearnIconButton(
            semanticLabel: 'もう一度',
            icon: Icons.refresh_rounded,
            onPressed: onReset,
          ),
        ),
      ],
    );
  }
}

class _WeightObjectButton extends StatelessWidget {
  final String label;
  final _WeightObjectKind kind;
  final bool selected;
  final VoidCallback onTap;

  const _WeightObjectButton({
    required this.label,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final objectVisual = _WeightObjectVisual(kind: kind, size: 58);
    final draggableObject = selected
        ? objectVisual
        : Draggable<_WeightObjectKind>(
            data: kind,
            dragAnchorStrategy: childDragAnchorStrategy,
            feedback: Material(
              color: Colors.transparent,
              child: _WeightObjectVisual(kind: kind, size: 58),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: objectVisual),
            child: objectVisual,
          );
    final content = InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: selected ? 0.45 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              draggableObject,
              const SizedBox(width: 16),
              Text(
                selected ? '$labelをのせました' : label,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return content;
  }
}

class _WeightObjectVisual extends StatelessWidget {
  final _WeightObjectKind kind;
  final double size;

  const _WeightObjectVisual({required this.kind, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _WeightObjectPainter(kind: kind)),
    );
  }
}

class _WeightObjectPainter extends CustomPainter {
  final _WeightObjectKind kind;

  const _WeightObjectPainter({required this.kind});

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case _WeightObjectKind.apple:
        _drawApple(canvas, size);
      case _WeightObjectKind.pencil:
        _drawPencil(canvas, size);
    }
  }

  void _drawApple(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width * 0.5, size.height * 0.58);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, s * 0.05),
        width: s * 0.72,
        height: s * 0.24,
      ),
      Paint()
        ..color = const Color(0x240F172A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );

    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.26)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.21,
        size.width * 0.32,
        size.height * 0.2,
        size.width * 0.24,
        size.height * 0.3,
      )
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.49,
        size.width * 0.18,
        size.height * 0.84,
        size.width * 0.43,
        size.height * 0.89,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.9,
        size.width * 0.52,
        size.height * 0.9,
        size.width * 0.57,
        size.height * 0.89,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.84,
        size.width * 0.92,
        size.height * 0.49,
        size.width * 0.76,
        size.height * 0.3,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.2,
        size.width * 0.58,
        size.height * 0.21,
        size.width * 0.5,
        size.height * 0.26,
      )
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.28),
          radius: 0.95,
          colors: const [
            Color(0xFFFF8A65),
            Color(0xFFE9432F),
            Color(0xFFB42318),
          ],
          stops: [0, 0.64, 1],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.27),
        width: s * 0.22,
        height: s * 0.1,
      ),
      Paint()..color = const Color(0x220F172A),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    final stem = Paint()
      ..color = const Color(0xFF854D0E)
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.25),
      Offset(size.width * 0.58, size.height * 0.08),
      stem,
    );
    final leaf = Path()
      ..moveTo(size.width * 0.58, size.height * 0.16)
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.02,
        size.width * 0.84,
        size.height * 0.12,
        size.width * 0.72,
        size.height * 0.25,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.27,
        size.width * 0.6,
        size.height * 0.22,
        size.width * 0.58,
        size.height * 0.16,
      );
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF15803D));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.44),
        width: s * 0.12,
        height: s * 0.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  void _drawPencil(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.45);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.85,
      height: s * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.04)),
      Paint()..color = const Color(0xFFFBBF24),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, s * 0.16, rect.height),
      Paint()..color = const Color(0xFFFCA5A5),
    );
    final tipPath = Path()
      ..moveTo(rect.right, rect.top)
      ..lineTo(rect.right + s * 0.18, 0)
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFFFDE68A));
    final leadPath = Path()
      ..moveTo(rect.right + s * 0.18, 0)
      ..lineTo(rect.right + s * 0.08, -s * 0.05)
      ..lineTo(rect.right + s * 0.08, s * 0.05)
      ..close();
    canvas.drawPath(leadPath, Paint()..color = const Color(0xFF111827));
    final linePaint = Paint()
      ..color = const Color(0xFFB45309)
      ..strokeWidth = s * 0.025;
    canvas.drawLine(
      Offset(rect.left + s * 0.2, rect.top),
      Offset(rect.left + s * 0.2, rect.bottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(rect.left + s * 0.28, rect.top),
      Offset(rect.left + s * 0.28, rect.bottom),
      linePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeightObjectPainter oldDelegate) {
    return kind != oldDelegate.kind;
  }
}

class _WeightScaleDragPanel extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final bool appleOnScale;
  final bool showInstructionNative;
  final VoidCallback onToggleInstructionNative;
  final bool showResultNative;
  final VoidCallback onToggleResultNative;
  final VoidCallback onAccept;
  final VoidCallback onReset;

  const _WeightScaleDragPanel({
    required this.selectedLanguage,
    required this.appleOnScale,
    required this.showInstructionNative,
    required this.onToggleInstructionNative,
    required this.showResultNative,
    required this.onToggleResultNative,
    required this.onAccept,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SupportedInstruction(
          line: const SupportLine(
            japanese: 'りんごをはかりの上にのせてみよう。',
            ruby: 'りんごをはかりの{上|うえ}にのせてみよう。',
            native: {
              AppLanguage.portuguese:
                  'Vamos colocar a maçã em cima da balança.',
              AppLanguage.tagalog:
                  'Ilagay natin ang mansanas sa ibabaw ng timbangan.',
              AppLanguage.vietnamese: 'Hãy đặt quả táo lên trên cái cân.',
            },
          ),
          language: selectedLanguage,
          showNative: showInstructionNative,
          onToggleNative: onToggleInstructionNative,
          vocabularyEntries: _weightVocabularyEntries,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            final apple = appleOnScale
                ? const SizedBox(width: 148, height: 82)
                : Draggable<String>(
                    data: 'apple',
                    feedback: const Material(
                      color: Colors.transparent,
                      child: _WeightObjectVisual(
                        kind: _WeightObjectKind.apple,
                        size: 64,
                      ),
                    ),
                    childWhenDragging: const Opacity(
                      opacity: 0.25,
                      child: _WeightScaleDish(),
                    ),
                    child: const _WeightScaleDish(
                      item: _WeightObjectVisual(
                        kind: _WeightObjectKind.apple,
                        size: 58,
                      ),
                    ),
                  );
            final scale = DragTarget<String>(
              onAcceptWithDetails: (_) => onAccept(),
              builder: (context, _, __) => _AnalogScale(
                grams: appleOnScale ? 300 : 0,
                child: appleOnScale
                    ? const _WeightObjectVisual(
                        kind: _WeightObjectKind.apple,
                        size: 48,
                      )
                    : const Text(
                        'ここにのせる',
                        style: TextStyle(
                          fontFamily: AppFonts.interface,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
              ),
            );
            if (!isWide) {
              return Column(
                children: [
                  Center(child: apple),
                  const SizedBox(height: 12),
                  scale,
                ],
              );
            }
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 148, child: Center(child: apple)),
                  const SizedBox(width: 32),
                  scale,
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        if (appleOnScale)
          _WeightSupportedResultBox(
            title: 'りんごの重さは300gです',
            nativeTitle: const {
              AppLanguage.portuguese: 'A maçã pesa 300 g.',
              AppLanguage.tagalog: 'Ang mansanas ay 300 g.',
              AppLanguage.vietnamese: 'Quả táo nặng 300 g.',
            },
            explanation: const SupportLine(
              japanese: '針が300gを指しています。重さを数字で表すときは、グラムを使います。グラムはgと書きます。',
              ruby:
                  '{針|はり}が300gを{指|さ}しています。{重|おも}さを{数字|すうじ}で{表|あらわ}すときは、グラムを{使|つか}います。グラムはgと{書|か}きます。',
              native: {
                AppLanguage.portuguese:
                    'O ponteiro aponta para 300 g. Para escrever o peso com números, usamos gramas. Grama se escreve g.',
                AppLanguage.tagalog:
                    'Ang karayom ay nakaturo sa 300 g. Ginagamit ang gramo para isulat ang bigat sa numero. Isinusulat ang gramo bilang g.',
                AppLanguage.vietnamese:
                    'Kim chỉ 300 g. Khi biểu thị khối lượng bằng số, ta dùng gam. Gam viết là g.',
              },
            ),
            selectedLanguage: selectedLanguage,
            showNative: showResultNative,
            onToggleNative: onToggleResultNative,
            vocabularyEntries: _weightVocabularyEntries,
            audioLabel: 'グラムの説明を聞く',
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _LearnIconButton(
            semanticLabel: 'もう一度',
            icon: Icons.refresh_rounded,
            onPressed: onReset,
          ),
        ),
      ],
    );
  }
}

class _WeightThousandPanel extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final int count;
  final bool showInstructionNative;
  final VoidCallback onToggleInstructionNative;
  final bool showResultNative;
  final VoidCallback onToggleResultNative;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  const _WeightThousandPanel({
    required this.selectedLanguage,
    required this.count,
    required this.showInstructionNative,
    required this.onToggleInstructionNative,
    required this.showResultNative,
    required this.onToggleResultNative,
    required this.onAdd,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final grams = count * 100;
    return Column(
      children: [
        _SupportedInstruction(
          line: const SupportLine(
            japanese: '100gのおもりを1こずつはかりにのせてみよう。',
            ruby: '100gのおもりを1こずつはかりにのせてみよう。',
            native: {
              AppLanguage.portuguese:
                  'Vamos colocar os pesos de 100 g, um de cada vez, na balança.',
              AppLanguage.tagalog:
                  'Ilagay natin ang mga pabigat na 100 g sa timbangan, isa-isa.',
              AppLanguage.vietnamese: 'Hãy đặt từng quả cân 100 g lên cân.',
            },
          ),
          language: selectedLanguage,
          showNative: showInstructionNative,
          onToggleNative: onToggleInstructionNative,
          vocabularyEntries: _weightVocabularyEntries,
        ),
        const SizedBox(height: 14),
        _AnalogScale(
          grams: grams,
          child: _WeightBlockTray(count: count),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: count >= 10 ? null : onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('100gを乗せる'),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _LearnIconButton(
            semanticLabel: 'もどす',
            icon: Icons.refresh_rounded,
            onPressed: onReset,
          ),
        ),
        if (count >= 10) ...[
          const SizedBox(height: 14),
          _WeightSupportedResultBox(
            title: '1000g = 1kg',
            // The equation is shared across languages, so only the sentence
            // below needs a translated version.
            nativeTitle: const {},
            explanation: const SupportLine(
              japanese: '1000gになりました。1000gを1キログラムといいます。',
              ruby: '1000gになりました。1000gを1キログラムといいます。',
              native: {
                AppLanguage.portuguese:
                    'Chegamos a 1000 g. Chamamos 1000 g de 1 quilograma.',
                AppLanguage.tagalog:
                    'Naging 1000 g na. Ang 1000 g ay tinatawag na 1 kilogramo.',
                AppLanguage.vietnamese:
                    'Đã được 1000 g. 1000 g được gọi là 1 ki-lô-gam.',
              },
            ),
            selectedLanguage: selectedLanguage,
            showNative: showResultNative,
            onToggleNative: onToggleResultNative,
            vocabularyEntries: _weightVocabularyEntries,
            audioLabel: 'キログラムの説明を聞く',
          ),
        ],
      ],
    );
  }
}

class _WeightKgGramPanel extends StatelessWidget {
  const _WeightKgGramPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [
              _WeightConversionRow(
                label: 'りんごと本',
                left: '1300g',
                right: '1kg300g',
              ),
              _WeightConversionRow(
                label: 'ランドセル',
                left: '1700g',
                right: '1kg700g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightConversionRow extends StatelessWidget {
  final String label;
  final String left;
  final String right;

  const _WeightConversionRow({
    required this.label,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(
                left,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B)),
              Text(
                right,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightTonLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _WeightTonLearn({required this.selectedLanguage});

  @override
  State<_WeightTonLearn> createState() => _WeightTonLearnState();
}

class _WeightTonLearnState extends State<_WeightTonLearn> {
  int _page = 0;
  int _loads = 0;
  bool _showNative = false;
  bool _showLoadInstructionNative = false;
  bool _showLoadResultNative = false;

  static const _lastPage = 1;

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: 'とても重いものは、トンで表すことがあります。',
          ruby: 'とても{重|おも}いものは、トンで{表|あらわ}すことがあります。',
          native: {
            AppLanguage.portuguese:
                'Coisas muito pesadas podem ser mostradas em toneladas.',
            AppLanguage.tagalog:
                'Ang napakabibigat ay puwedeng ipakita sa tonelada.',
            AppLanguage.vietnamese:
                'Đồ rất nặng có thể ghi bằng tấn.',
          },
        ),
      ],
      1 => const [
        SupportLine(
          japanese: '100kgの荷物を10こ積むと、何kgになるかな？',
          ruby: '100kgの{荷物|にもつ}を10こ{積|つ}むと、{何|なん}kgになるかな？',
          native: {
            AppLanguage.portuguese:
                'Ao colocar 10 cargas de 100 kg no caminhão, quantos quilogramas serão ao todo?',
            AppLanguage.tagalog:
                'Kung magkarga ng 10 pirasong 100 kg sa trak, ilang kilogramo lahat?',
            AppLanguage.vietnamese:
                'Khi chất 10 kiện 100 kg lên xe tải, tổng cộng bao nhiêu kilôgam?',
          },
        ),
      ],
      _ => const [
        SupportLine(
          japanese: '100kgの荷物を10こ積むと、何kgになるかな？',
          ruby: '100kgの{荷物|にもつ}を10こ{積|つ}むと、{何|なん}kgになるかな？',
          native: {
            AppLanguage.portuguese:
                'Ao colocar 10 cargas de 100 kg no caminhão, quantos quilogramas serão ao todo?',
            AppLanguage.tagalog:
                'Kung magkarga ng 10 pirasong 100 kg sa trak, ilang kilogramo lahat?',
            AppLanguage.vietnamese:
                'Khi chất 10 kiện 100 kg lên xe tải, tổng cộng bao nhiêu kilôgam?',
          },
        ),
      ],
    };
  }

  void _speak() {
    LearningAudio.speakJapanese(
      context,
      label: 'トン',
      text: _pageLines.map((line) => line.japanese).join(' '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RemainderLearnShell(
      icon: Icons.local_shipping_rounded,
      title: 'トンを使ってみよう',
      selectedLanguage: widget.selectedLanguage,
      showNative: _showNative,
      onToggleNative: () => setState(() => _showNative = !_showNative),
      onAudio: _speak,
      page: _page,
      lastPage: _lastPage,
      onPrevious: () => setState(() => _page = math.max(0, _page - 1)),
      onNext: () => setState(() => _page = math.min(_lastPage, _page + 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SupportedTextLines(
            lines: _pageLines,
            language: widget.selectedLanguage,
            showNative: _showNative,
            vocabularyEntries: _weightVocabularyEntries,
            enableLearningSupport: true,
          ),
          const SizedBox(height: 18),
          switch (_page) {
            0 => const _TonIntroPanel(),
            1 => _TonLoadPanel(
              loads: _loads,
              selectedLanguage: widget.selectedLanguage,
              showInstructionNative: _showLoadInstructionNative,
              showResultNative: _showLoadResultNative,
              onToggleInstructionNative: () => setState(
                () => _showLoadInstructionNative = !_showLoadInstructionNative,
              ),
              onToggleResultNative: () => setState(
                () => _showLoadResultNative = !_showLoadResultNative,
              ),
              onAdd: () => setState(() {
                if (_loads < 10) _loads++;
              }),
              onReset: () => setState(() => _loads = 0),
            ),
            _ => _TonLoadPanel(
              loads: _loads,
              selectedLanguage: widget.selectedLanguage,
              showInstructionNative: _showLoadInstructionNative,
              showResultNative: _showLoadResultNative,
              onToggleInstructionNative: () => setState(
                () => _showLoadInstructionNative = !_showLoadInstructionNative,
              ),
              onToggleResultNative: () => setState(
                () => _showLoadResultNative = !_showLoadResultNative,
              ),
              onAdd: () => setState(() {
                if (_loads < 10) _loads++;
              }),
              onReset: () => setState(() => _loads = 0),
            ),
          },
        ],
      ),
    );
  }
}

class _TonIntroPanel extends StatelessWidget {
  const _TonIntroPanel();

  @override
  Widget build(BuildContext context) {
    return const _HeavyObjectRow();
  }
}

class _HeavyObjectRow extends StatelessWidget {
  const _HeavyObjectRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final cards = const [
          _HeavyObjectCard(kind: _HeavyObjectKind.car, label: '自動車'),
          _HeavyObjectCard(kind: _HeavyObjectKind.truck, label: 'トラック'),
          _HeavyObjectCard(kind: _HeavyObjectKind.elephant, label: 'ゾウ'),
        ];
        if (!isWide) {
          return const Column(
            children: [
              _HeavyObjectCard(kind: _HeavyObjectKind.car, label: '自動車'),
              SizedBox(height: 10),
              _HeavyObjectCard(kind: _HeavyObjectKind.truck, label: 'トラック'),
              SizedBox(height: 10),
              _HeavyObjectCard(kind: _HeavyObjectKind.elephant, label: 'ゾウ'),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

enum _HeavyObjectKind { car, truck, elephant }

class _HeavyObjectCard extends StatelessWidget {
  final _HeavyObjectKind kind;
  final String label;

  const _HeavyObjectCard({required this.kind, required this.label});

  String get _approxWeight {
    return switch (kind) {
      _HeavyObjectKind.car => 'およそ 1t',
      _HeavyObjectKind.truck => 'およそ 4t',
      _HeavyObjectKind.elephant => 'およそ 5t',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 82,
            child: CustomPaint(painter: _HeavyObjectPainter(kind: kind)),
          ),
          const SizedBox(height: 8),
          if (kind == _HeavyObjectKind.car)
            RubyText(
              text: '{自動車|じどうしゃ}',
              enableLearningSupport: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              label,
              style: const TextStyle(
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _approxWeight,
            style: const TextStyle(
              fontSize: 18,
              height: 1.2,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeavyObjectPainter extends CustomPainter {
  final _HeavyObjectKind kind;

  const _HeavyObjectPainter({required this.kind});

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case _HeavyObjectKind.car:
        _drawCar(canvas, size);
      case _HeavyObjectKind.truck:
        _drawTruck(canvas, size);
      case _HeavyObjectKind.elephant:
        _drawElephant(canvas, size);
    }
  }

  void _drawCar(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF2563EB);
    final bodyShade = Paint()..color = const Color(0xFF1D4ED8);
    final dark = Paint()..color = const Color(0xFF1E293B);
    final outline = Paint()
      ..color = const Color(0xFF1E40AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final window = Paint()..color = const Color(0xFFEFF6FF);
    final car = Path()
      ..moveTo(size.width * 0.12, size.height * 0.58)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.43,
        size.width * 0.2,
        size.height * 0.38,
        size.width * 0.29,
        size.height * 0.38,
      )
      ..lineTo(size.width * 0.38, size.height * 0.22)
      ..lineTo(size.width * 0.6, size.height * 0.22)
      ..lineTo(size.width * 0.74, size.height * 0.38)
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.39,
        size.width * 0.9,
        size.height * 0.45,
        size.width * 0.91,
        size.height * 0.57,
      )
      ..lineTo(size.width * 0.88, size.height * 0.65)
      ..lineTo(size.width * 0.14, size.height * 0.65)
      ..close();
    canvas.drawPath(car, body);
    canvas.drawPath(car, outline);
    final sideShade = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.52,
        size.width * 0.58,
        size.height * 0.08,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(sideShade, bodyShade);
    final frontWindow = Path()
      ..moveTo(size.width * 0.43, size.height * 0.27)
      ..lineTo(size.width * 0.56, size.height * 0.27)
      ..lineTo(size.width * 0.65, size.height * 0.38)
      ..lineTo(size.width * 0.4, size.height * 0.38)
      ..close();
    canvas.drawPath(frontWindow, window);
    final rearWindow = Path()
      ..moveTo(size.width * 0.31, size.height * 0.38)
      ..lineTo(size.width * 0.39, size.height * 0.27)
      ..lineTo(size.width * 0.42, size.height * 0.38)
      ..close();
    canvas.drawPath(rearWindow, window);
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.54),
      3.8,
      Paint()..color = const Color(0xFFFDE68A),
    );
    canvas.drawCircle(
      Offset(size.width * 0.17, size.height * 0.55),
      3.2,
      Paint()..color = const Color(0xFFFCA5A5),
    );
    _drawWheel(canvas, Offset(size.width * 0.3, size.height * 0.68), dark);
    _drawWheel(canvas, Offset(size.width * 0.7, size.height * 0.68), dark);
  }

  void _drawTruck(Canvas canvas, Size size) {
    final cargo = Paint()..color = const Color(0xFFCBD5E1);
    final cargoShade = Paint()..color = const Color(0xFF94A3B8);
    final cab = Paint()..color = const Color(0xFF2563EB);
    final cabShade = Paint()..color = const Color(0xFF1D4ED8);
    final dark = Paint()..color = const Color(0xFF1E293B);
    final outline = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final window = Paint()..color = const Color(0xFFE0F2FE);
    final cargoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.24,
        size.width * 0.52,
        size.height * 0.38,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(cargoRect, cargo);
    canvas.drawRRect(cargoRect, outline);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.33),
      Offset(size.width * 0.52, size.height * 0.33),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.62)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.53,
        size.width * 0.48,
        size.height * 0.09,
      ),
      cargoShade,
    );
    final cabPath = Path()
      ..moveTo(size.width * 0.61, size.height * 0.62)
      ..lineTo(size.width * 0.61, size.height * 0.37)
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.28,
        size.width * 0.72,
        size.height * 0.28,
      )
      ..lineTo(size.width * 0.82, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.87,
        size.height * 0.37,
        size.width * 0.89,
        size.height * 0.48,
      )
      ..lineTo(size.width * 0.89, size.height * 0.62)
      ..close();
    canvas.drawPath(cabPath, cab);
    canvas.drawPath(cabPath, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.69,
          size.height * 0.34,
          size.width * 0.12,
          size.height * 0.1,
        ),
        const Radius.circular(3),
      ),
      window,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.54,
        size.width * 0.24,
        size.height * 0.08,
      ),
      cabShade,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.65),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    _drawWheel(canvas, Offset(size.width * 0.26, size.height * 0.7), dark);
    _drawWheel(canvas, Offset(size.width * 0.7, size.height * 0.7), dark);
    _drawWheel(canvas, Offset(size.width * 0.82, size.height * 0.7), dark);
  }

  void _drawElephant(Canvas canvas, Size size) {
    final animal = Paint()..color = const Color(0xFF9AA8BC);
    final animalDark = Paint()..color = const Color(0xFF738399);
    final dark = Paint()..color = const Color(0xFF334155);
    final ear = Paint()..color = const Color(0xFFB9C5D5);
    final outline = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9;

    // Four legs sit behind one continuous body, so the animal reads as a
    // single side-view elephant instead of a stack of separate shapes.
    for (final x in [0.22, 0.39, 0.53, 0.63]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * x,
          size.height * 0.53,
          size.width * 0.085,
          size.height * 0.25,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(leg, animalDark);
      canvas.drawRRect(leg, outline);
    }

    final body = Path()
      ..moveTo(size.width * 0.16, size.height * 0.57)
      ..cubicTo(
        size.width * 0.13,
        size.height * 0.46,
        size.width * 0.16,
        size.height * 0.29,
        size.width * 0.3,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.17,
        size.width * 0.63,
        size.height * 0.22,
        size.width * 0.7,
        size.height * 0.34,
      )
      ..lineTo(size.width * 0.7, size.height * 0.58)
      ..cubicTo(
        size.width * 0.57,
        size.height * 0.65,
        size.width * 0.31,
        size.height * 0.67,
        size.width * 0.16,
        size.height * 0.57,
      )
      ..close();
    canvas.drawPath(body, animal);
    canvas.drawPath(body, outline);

    final headCenter = Offset(size.width * 0.72, size.height * 0.39);
    canvas.drawCircle(headCenter, size.height * 0.17, animal);
    canvas.drawCircle(headCenter, size.height * 0.17, outline);
    final earOval = Rect.fromCenter(
      center: Offset(size.width * 0.65, size.height * 0.4),
      width: size.width * 0.19,
      height: size.height * 0.29,
    );
    canvas.drawOval(earOval, ear);
    canvas.drawOval(earOval, outline);

    final trunk = Path()
      ..moveTo(size.width * 0.82, size.height * 0.43)
      ..cubicTo(
        size.width * 0.91,
        size.height * 0.46,
        size.width * 0.92,
        size.height * 0.62,
        size.width * 0.88,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.76,
        size.width * 0.8,
        size.height * 0.71,
      );
    canvas.drawPath(
      trunk,
      Paint()
        ..color = const Color(0xFF9AA8BC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      trunk,
      Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.18, size.height * 0.39)
        ..quadraticBezierTo(
          size.width * 0.08,
          size.height * 0.34,
          size.width * 0.07,
          size.height * 0.47,
        ),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(size.width * 0.77, size.height * 0.35), 2.2, dark);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.82, size.height * 0.5)
        ..quadraticBezierTo(
          size.width * 0.87,
          size.height * 0.49,
          size.width * 0.88,
          size.height * 0.54,
        ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawWheel(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 8, paint);
    canvas.drawCircle(center, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _HeavyObjectPainter oldDelegate) {
    return kind != oldDelegate.kind;
  }
}

class _TonLoadPanel extends StatelessWidget {
  final int loads;
  final AppLanguage selectedLanguage;
  final bool showInstructionNative;
  final bool showResultNative;
  final VoidCallback onToggleInstructionNative;
  final VoidCallback onToggleResultNative;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  const _TonLoadPanel({
    required this.loads,
    required this.selectedLanguage,
    required this.showInstructionNative,
    required this.showResultNative,
    required this.onToggleInstructionNative,
    required this.onToggleResultNative,
    required this.onAdd,
    required this.onReset,
  });

  static const _instruction = SupportLine(
    japanese: '100kgの荷物を、トラックに1こずつ積んでみよう。',
    ruby: '100kgの{荷物|にもつ}を、トラックに1こずつ{積|つ}んでみよう。',
    native: {
      AppLanguage.portuguese:
          'Vamos colocar as cargas de 100 kg no caminhão, uma por vez.',
      AppLanguage.tagalog:
          'Ilagay natin ang mga kargang 100 kg sa trak, isa-isa.',
      AppLanguage.vietnamese:
          'Hãy chất từng kiện 100 kg lên xe tải.',
    },
  );

  static const _resultExplanation = SupportLine(
    japanese: '100kgの荷物が10こで、1000kgになります。1000kgを1トンといいます。',
    ruby: '100kgの{荷物|にもつ}が10こで、1000kgになります。1000kgを1トンといいます。',
    native: {
      AppLanguage.portuguese:
          'Dez cargas de 100 kg fazem 1000 kg. Chamamos 1000 kg de 1 tonelada.',
      AppLanguage.tagalog:
          'Sampung kargang 100 kg ay 1000 kg. Ang 1000 kg ay 1 tonelada.',
      AppLanguage.vietnamese:
          'Mười kiện 100 kg thành 1000 kg. 1000 kg gọi là 1 tấn.',
    },
  );

  @override
  Widget build(BuildContext context) {
    final kg = loads * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InstructionStrip(
          message: _instruction.japanese,
          isSuccess: false,
          language: selectedLanguage,
          showNative: showInstructionNative,
          instructionLine: _instruction,
          onToggleNative: onToggleInstructionNative,
          vocabularyEntries: _weightVocabularyEntries,
          learningSupportMode: LearningSupportMode.rubyAndDictionary,
        ),
        const SizedBox(height: 18),
        Center(child: _TonTruckLoadVisual(loads: loads)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            loads >= 10 ? '1000kg = 1t' : '${kg}kg',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: loads >= 10 ? null : onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('100kgを積む'),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _LearnIconButton(
            semanticLabel: 'もどす',
            icon: Icons.refresh_rounded,
            onPressed: onReset,
          ),
        ),
        if (loads >= 10) ...[
          const SizedBox(height: 18),
          _WeightSupportedResultBox(
            title: '1000kg = 1t',
            nativeTitle: const {AppLanguage.portuguese: '1000 kg = 1 t',
      AppLanguage.tagalog: '1000 kg = 1 t',
      AppLanguage.vietnamese: '1000 kg = 1 t',},
            explanation: _resultExplanation,
            selectedLanguage: selectedLanguage,
            showNative: showResultNative,
            onToggleNative: onToggleResultNative,
            vocabularyEntries: _weightVocabularyEntries,
            audioLabel: '1トンの説明',
          ),
        ],
      ],
    );
  }
}

class _TonTruckLoadVisual extends StatelessWidget {
  final int loads;

  const _TonTruckLoadVisual({required this.loads});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 440,
        height: 218,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _TonTruckPainter()),
            ),
            Positioned(
              left: 72,
              top: 54,
              width: 230,
              height: 88,
              child: _TonLoadTray(loads: loads),
            ),
          ],
        ),
      ),
    );
  }
}

class _TonLoadTray extends StatelessWidget {
  final int loads;

  const _TonLoadTray({required this.loads});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        for (var i = 0; i < 10; i++)
          Opacity(opacity: i < loads ? 1 : 0, child: const _TonLoadBox()),
      ],
    );
  }
}

class _TonLoadBox extends StatelessWidget {
  const _TonLoadBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFDE68A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFEAB308)),
      ),
      child: const Text(
        '100',
        style: TextStyle(
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF713F12),
        ),
      ),
    );
  }
}

class _TonTruckPainter extends CustomPainter {
  const _TonTruckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final dark = Paint()..color = const Color(0xFF1F2937);
    final cargo = Paint()..color = const Color(0xFFE2E8F0);
    final cargoShade = Paint()..color = const Color(0xFFCBD5E1);
    final cab = Paint()..color = const Color(0xFF2563EB);
    final cabShade = Paint()..color = const Color(0xFF1D4ED8);
    final window = Paint()..color = const Color(0xFFE0F2FE);

    final bed = RRect.fromRectAndRadius(
      Rect.fromLTWH(42, 42, 286, 118),
      const Radius.circular(14),
    );
    canvas.drawRRect(bed, cargo);
    canvas.drawRRect(bed, outline);

    canvas.drawRect(Rect.fromLTWH(48, 130, 278, 30), cargoShade);
    canvas.drawLine(
      const Offset(58, 62),
      const Offset(312, 62),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final cabPath = Path()
      ..moveTo(326, 160)
      ..lineTo(326, 86)
      ..quadraticBezierTo(334, 62, 360, 62)
      ..lineTo(386, 62)
      ..quadraticBezierTo(410, 86, 416, 122)
      ..lineTo(416, 160)
      ..close();
    canvas.drawPath(cabPath, cab);
    canvas.drawPath(cabPath, outline);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(354, 78, 36, 25),
        const Radius.circular(5),
      ),
      window,
    );
    canvas.drawRect(const Rect.fromLTWH(330, 132, 78, 28), cabShade);
    canvas.drawCircle(
      const Offset(409, 128),
      4.5,
      Paint()..color = const Color(0xFFFDE68A),
    );

    canvas.drawLine(
      const Offset(34, 166),
      const Offset(422, 166),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    _drawWheel(canvas, const Offset(108, 178), dark);
    _drawWheel(canvas, const Offset(286, 178), dark);
    _drawWheel(canvas, const Offset(372, 178), dark);
  }

  void _drawWheel(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 18, paint);
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF94A3B8));
  }

  @override
  bool shouldRepaint(covariant _TonTruckPainter oldDelegate) => false;
}

class _WeightScaleDish extends StatelessWidget {
  final Widget? item;

  const _WeightScaleDish({this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 82,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 37,
            child: const SizedBox(
              width: 168,
              height: 44,
              child: CustomPaint(painter: _WeightSourcePlatePainter()),
            ),
          ),
          if (item != null) Positioned(top: 0, child: item!),
        ],
      ),
    );
  }
}

class _WeightSourcePlatePainter extends CustomPainter {
  const _WeightSourcePlatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(1, 2, size.width - 2, size.height - 4);
    final inner = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 1),
      width: size.width - 24,
      height: size.height - 18,
    );
    canvas.drawOval(outer, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawOval(
      outer,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(inner, Paint()..color = Colors.white);
    canvas.drawOval(
      inner,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WeightSourcePlatePainter oldDelegate) => false;
}

class _AnalogScale extends StatelessWidget {
  final int grams;
  final Widget child;

  const _AnalogScale({required this.grams, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 300,
            height: 210,
            child: CustomPaint(painter: _ScalePainter(grams: grams)),
          ),
          const SizedBox(height: 8),
          Container(
            width: 264,
            height: 92,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _WeightBlockTray extends StatelessWidget {
  final int count;

  const _WeightBlockTray({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 72,
      child: GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.34,
        children: [
          for (var i = 0; i < 10; i++)
            Opacity(
              opacity: i < count ? 1 : 0,
              child: const _SmallWeightBlock(),
            ),
        ],
      ),
    );
  }
}

class _SmallWeightBlock extends StatelessWidget {
  const _SmallWeightBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '100g',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SoftResultBox extends StatelessWidget {
  final String text;
  final String emphasized;
  final String? highlightedTerm;

  const _SoftResultBox({
    required this.text,
    required this.emphasized,
    String? highlightedTerm,
  }) : highlightedTerm = highlightedTerm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emphasized,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 8),
          _HighlightedBodyText(text: text, highlightedTerm: highlightedTerm),
        ],
      ),
    );
  }
}

class _WeightSupportedResultBox extends StatelessWidget {
  final String title;
  final Map<AppLanguage, String> nativeTitle;
  final SupportLine explanation;
  final AppLanguage selectedLanguage;
  final bool showNative;
  final VoidCallback onToggleNative;
  final List<VocabularyEntry> vocabularyEntries;
  final String audioLabel;

  const _WeightSupportedResultBox({
    required this.title,
    required this.nativeTitle,
    required this.explanation,
    required this.selectedLanguage,
    required this.showNative,
    required this.onToggleNative,
    required this.vocabularyEntries,
    required this.audioLabel,
  });

  @override
  Widget build(BuildContext context) {
    final translatedTitle = nativeTitle[selectedLanguage] ?? '';
    final canShowNative =
        selectedLanguage != AppLanguage.japanese && translatedTitle.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 28,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                    if (showNative && canShowNative) ...[
                      const SizedBox(height: 3),
                      Text(
                        translatedTitle,
                        style: const TextStyle(
                          fontFamily: AppFonts.interface,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _IconSupportActions(
                language: selectedLanguage,
                showNative: showNative,
                translateLabel: showNative
                    ? '日本語で見る'
                    : '${selectedLanguage.label}で見る',
                audioLabel: audioLabel,
                onToggleNative: onToggleNative,
                onAudio: () => LearningAudio.speakJapanese(
                  context,
                  label: '重さの説明',
                  text: '$title ${explanation.japanese}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RubyText(
            text: explanation.rubyText,
            vocabularyEntries: vocabularyEntries,
            language: selectedLanguage,
            enableLearningSupport: true,
            style: const TextStyle(
              fontFamily: AppFonts.interface,
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (showNative &&
              selectedLanguage != AppLanguage.japanese &&
              explanation.nativeFor(selectedLanguage).isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              explanation.nativeFor(selectedLanguage),
              style: const TextStyle(
                fontFamily: AppFonts.interface,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightedBodyText extends StatelessWidget {
  final String text;
  final String? highlightedTerm;

  const _HighlightedBodyText({
    required this.text,
    required this.highlightedTerm,
  });

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 17,
      height: 1.55,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    final term = highlightedTerm;
    if (term == null || term.isEmpty || !text.contains(term)) {
      return Text(text, style: baseStyle);
    }
    final parts = text.split(term);
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i != parts.length - 1)
              TextSpan(
                text: term,
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BalancePainter extends CustomPainter {
  final bool appleOnBalance;
  final bool pencilOnBalance;

  const _BalancePainter({
    required this.appleOnBalance,
    required this.pencilOnBalance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.34);
    final tilt = switch ((appleOnBalance, pencilOnBalance)) {
      (true, true) => -0.08,
      (true, false) => -0.16,
      (false, true) => 0.08,
      _ => 0.0,
    };
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final footPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, center.translate(0, 94), paint);
    canvas.drawLine(
      center.translate(-50, 94),
      center.translate(50, 94),
      footPaint,
    );
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF475569));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.drawLine(const Offset(-130, 0), const Offset(130, 0), paint);
    _drawChain(canvas, const Offset(-104, 0), const Offset(-104, 64));
    _drawChain(canvas, const Offset(104, 0), const Offset(104, 64));
    _drawPan(
      canvas,
      const Offset(-104, 72),
      fillPaint,
      appleOnBalance ? _WeightObjectKind.apple : null,
    );
    _drawPan(
      canvas,
      const Offset(104, 72),
      fillPaint,
      pencilOnBalance ? _WeightObjectKind.pencil : null,
    );
    canvas.restore();
  }

  void _drawChain(Canvas canvas, Offset start, Offset end) {
    final chainPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, chainPaint);
  }

  void _drawPan(
    Canvas canvas,
    Offset center,
    Paint fillPaint,
    _WeightObjectKind? object,
  ) {
    final panPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 108, height: 30),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 108, height: 30),
      panPaint,
    );
    if (object == null) return;
    canvas.save();
    canvas.translate(center.dx - 24, center.dy - 48);
    _WeightObjectPainter(kind: object).paint(canvas, const Size(48, 48));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BalancePainter oldDelegate) {
    return appleOnBalance != oldDelegate.appleOnBalance ||
        pencilOnBalance != oldDelegate.pencilOnBalance;
  }
}

class _ScalePainter extends CustomPainter {
  final int grams;

  const _ScalePainter({required this.grams});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 8, size.width - 40, size.height - 18),
      const Radius.circular(30),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFEFF6FF)],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    final dialCenter = Offset(size.width / 2, size.height * 0.42);
    final dialRadius = math.min(size.width, size.height) * 0.34;
    canvas.drawCircle(dialCenter, dialRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      dialCenter,
      dialRadius,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    final arcRect = Rect.fromCircle(
      center: dialCenter,
      radius: dialRadius - 18,
    );
    canvas.drawArc(
      arcRect,
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i <= 20; i++) {
      final angle = math.pi * 1.12 + math.pi * 0.76 * i / 20;
      final isMajor = i % 10 == 0;
      final isMedium = i % 5 == 0;
      final outer =
          dialCenter +
          Offset(math.cos(angle), math.sin(angle)) * (dialRadius - 12);
      final inner =
          dialCenter +
          Offset(math.cos(angle), math.sin(angle)) *
              (dialRadius -
                  (isMajor
                      ? 32
                      : isMedium
                      ? 26
                      : 20));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = const Color(0xFF64748B)
          ..strokeWidth = isMajor ? 3 : 1.6
          ..strokeCap = StrokeCap.round,
      );
      if (isMajor) {
        final value = i == 0
            ? '0'
            : i == 10
            ? '500'
            : '1kg';
        _paintText(
          canvas,
          value,
          dialCenter +
              Offset(math.cos(angle), math.sin(angle)) * (dialRadius - 46),
          13,
          const Color(0xFF334155),
        );
      }
    }

    final clamped = grams.clamp(0, 1000);
    final angle = math.pi * 1.12 + math.pi * 0.76 * clamped / 1000;
    final needleEnd =
        dialCenter +
        Offset(math.cos(angle), math.sin(angle)) * (dialRadius - 34);
    canvas.drawLine(
      dialCenter,
      needleEnd,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(dialCenter, 7, Paint()..color = const Color(0xFFEF4444));
    _paintText(
      canvas,
      '${grams}g',
      Offset(size.width / 2, size.height * 0.54),
      24,
      const Color(0xFF111827),
      weight: FontWeight.w800,
    );

    final trayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.82),
        width: size.width * 0.58,
        height: 24,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(trayRect, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(
      trayRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w700,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: size,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ScalePainter oldDelegate) {
    return grams != oldDelegate.grams;
  }
}

const _weightVocabularyEntries = [
  VocabularyEntry(
    term: '重い',
    reading: 'おもい',
    simpleJapanese: '持ったときに、力がたくさんいる感じです。',
    translations: {AppLanguage.portuguese: 'pesado',
      AppLanguage.tagalog: 'mabigat',
      AppLanguage.vietnamese: 'nặng',},
    exampleSentence: 'りんごはえんぴつより重いです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '軽い',
    reading: 'かるい',
    simpleJapanese: '持ったときに、力があまりいらない感じです。',
    translations: {AppLanguage.portuguese: 'leve',
      AppLanguage.tagalog: 'magaan',
      AppLanguage.vietnamese: 'nhẹ',},
    exampleSentence: 'えんぴつは軽いです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '重さ',
    reading: 'おもさ',
    simpleJapanese: 'ものがどれくらい重いかです。',
    translations: {AppLanguage.portuguese: 'peso',
      AppLanguage.tagalog: 'timbang / bigat',
      AppLanguage.vietnamese: 'khối lượng',},
    exampleSentence: '重さをはかります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'はかり',
    reading: 'はかり',
    simpleJapanese: '重さを調べる道具です。',
    translations: {AppLanguage.portuguese: 'balança',
      AppLanguage.tagalog: 'timbangan',
      AppLanguage.vietnamese: 'cân',},
    exampleSentence: 'りんごをはかりに乗せます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '目盛り',
    reading: 'めもり',
    simpleJapanese: '量を読むための小さなしるしです。',
    translations: {AppLanguage.portuguese: 'marcação / escala',
      AppLanguage.tagalog: 'marka / iskala',
      AppLanguage.vietnamese: 'vạch chia',},
    exampleSentence: '目盛りを見ます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'グラム',
    reading: 'ぐらむ',
    simpleJapanese: '重さの単位です。gと書きます。',
    translations: {AppLanguage.portuguese: 'grama',
      AppLanguage.tagalog: 'gramo',
      AppLanguage.vietnamese: 'gam',},
    exampleSentence: '300gです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'キログラム',
    reading: 'きろぐらむ',
    simpleJapanese: '重さの単位です。1kgは1000gです。',
    translations: {AppLanguage.portuguese: 'quilograma',
      AppLanguage.tagalog: 'kilogramo',
      AppLanguage.vietnamese: 'kilôgam',},
    exampleSentence: '1kgは1000gです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '荷物',
    reading: 'にもつ',
    simpleJapanese: '運んだり、置いたりするものです。',
    translations: {AppLanguage.portuguese: 'carga / bagagem',
      AppLanguage.tagalog: 'karga / dala',
      AppLanguage.vietnamese: 'hàng / vật mang',},
    exampleSentence: '荷物をトラックに積みます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '積む',
    reading: 'つむ',
    simpleJapanese: 'ものを重ねたり、乗り物に入れたりすることです。',
    translations: {AppLanguage.portuguese: 'carregar / empilhar',
      AppLanguage.tagalog: 'magkarga / magpatong',
      AppLanguage.vietnamese: 'chất / chất lên',},
    exampleSentence: '荷物をトラックに積みます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'トン',
    reading: 'とん',
    simpleJapanese: 'とても重いものに使う単位です。tと書きます。',
    translations: {AppLanguage.portuguese: 'tonelada',
      AppLanguage.tagalog: 'tonelada',
      AppLanguage.vietnamese: 'tấn',},
    exampleSentence: '1000kgは1tです。',
    category: 'math_language',
  ),
];

class LearnNativeScope extends InheritedWidget {
  final bool showNative;
  final AppLanguage language;
  final VoidCallback toggleNative;

  const LearnNativeScope({
    required this.showNative,
    required this.language,
    required this.toggleNative,
    required super.child,
  });

  static LearnNativeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LearnNativeScope>();
  }

  @override
  bool updateShouldNotify(LearnNativeScope oldWidget) {
    return showNative != oldWidget.showNative || language != oldWidget.language;
  }
}

class _RemainderLearnShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? titleRuby;
  final List<VocabularyEntry> titleVocabularyEntries;
  final AppLanguage selectedLanguage;
  final bool showNative;
  final VoidCallback onToggleNative;
  final VoidCallback onAudio;
  final int page;
  final int lastPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  const _RemainderLearnShell({
    required this.icon,
    required this.title,
    this.titleRuby,
    this.titleVocabularyEntries = const [],
    required this.selectedLanguage,
    required this.showNative,
    required this.onToggleNative,
    required this.onAudio,
    required this.page,
    required this.lastPage,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LearnNativeScope(
      showNative: showNative,
      language: selectedLanguage,
      toggleNative: onToggleNative,
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LearnHeaderIcon(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: IgnorePointer(
                  ignoring: titleVocabularyEntries.isEmpty,
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: RubyText(
                      text: titleRuby ?? title,
                      language: selectedLanguage,
                      vocabularyEntries: titleVocabularyEntries,
                      enableLearningSupport: titleVocabularyEntries.isNotEmpty,
                      learningSupportMode: titleVocabularyEntries.isEmpty
                          ? LearningSupportMode.rubyOnly
                          : LearningSupportMode.rubyAndDictionary,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _IconSupportActions(
                language: selectedLanguage,
                showNative: showNative,
                translateLabel: '翻訳',
                audioLabel: '音声',
                onToggleNative: onToggleNative,
                onAudio: onAudio,
              ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(page), child: child),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              OutlinedButton(
                onPressed: page == 0 ? null : onPrevious,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('もどる'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: page == lastPage ? null : onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('つぎ'),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

const _remainderLearnVocabulary = [
  ...equalShareVocabularyEntries,
  VocabularyEntry(
    term: 'あまり',
    reading: 'あまり',
    simpleJapanese: '分けたあとに残る数です。',
    translations: {AppLanguage.portuguese: 'resto / sobra',
      AppLanguage.tagalog: 'sobra / natira',
      AppLanguage.vietnamese: 'số dư',},
    exampleSentence: '7 ÷ 3 = 2 あまり 1 です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'わる数',
    reading: 'わるかず',
    simpleJapanese: '何こずつ、または何人で分けるかを表す数です。',
    translations: {AppLanguage.portuguese: 'divisor',
      AppLanguage.tagalog: 'panghati',
      AppLanguage.vietnamese: 'số chia',},
    exampleSentence: '7 ÷ 3 の3は、わる数です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'わられる数',
    reading: 'わられるかず',
    simpleJapanese: 'はじめにある全部の数です。',
    translations: {AppLanguage.portuguese: 'número que será dividido',
      AppLanguage.tagalog: 'bilang na hahatiin',
      AppLanguage.vietnamese: 'số bị chia',},
    exampleSentence: '7 ÷ 3 の7は、わられる数です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '残ります',
    reading: 'のこる',
    simpleJapanese: 'まだある、という意味です。',
    translations: {AppLanguage.portuguese: 'sobra / fica',
      AppLanguage.tagalog: 'natitira',
      AppLanguage.vietnamese: 'còn lại',},
    exampleSentence: '1こ残ります。',
    category: 'math_language',
  ),
];

final _remainderContextVocabulary = [
  VocabularyEntry(
    term: '長いす',
    surfaces: const ['長いす', '長椅子'],
    reading: 'ながいす',
    simpleJapanese: '何人かがいっしょに座れるいすです。',
    translations: nativeText(
      portuguese: 'banco comprido',
      tagalog: 'mahabang upuan / bangko',
      vietnamese: 'ghế dài',
    ),
    exampleSentence: '4人がけの長いすがあります。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: '何台',
    reading: 'なんだい',
    simpleJapanese: '車や長いすなどの数を聞く言い方です。',
    translations: {AppLanguage.portuguese: 'quantos',
      AppLanguage.tagalog: 'ilan',
      AppLanguage.vietnamese: 'bao nhiêu',},
    exampleSentence: '長いすは何台いりますか。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '必要',
    reading: 'ひつよう',
    simpleJapanese: 'なくてはならないことです。',
    translations: {AppLanguage.portuguese: 'necessário',
      AppLanguage.tagalog: 'kailangan',
      AppLanguage.vietnamese: 'cần',},
    exampleSentence: 'もう1台必要です。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '場面',
    reading: 'ばめん',
    simpleJapanese: '問題で起きていることです。',
    translations: {AppLanguage.portuguese: 'situação',
      AppLanguage.tagalog: 'sitwasyon',
      AppLanguage.vietnamese: 'tình huống',},
    exampleSentence: '問題の場面に戻って考えます。',
    category: 'school_japanese',
  ),
];

class _InteractiveRemainderShare extends StatefulWidget {
  final AppLanguage language;

  const _InteractiveRemainderShare({required this.language});

  @override
  State<_InteractiveRemainderShare> createState() =>
      _InteractiveRemainderShareState();
}

class _InteractiveRemainderShareState
    extends State<_InteractiveRemainderShare> {
  final List<int> _groupCounts = List<int>.filled(3, 0);
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  int get _placedCount => _groupCounts.fold(0, (sum, count) => sum + count);
  int get _remainingCount => 7 - _placedCount;
  bool get _isComplete => _groupCounts.every((count) => count == 2);

  void _placeStrawberry(int index) {
    if (_groupCounts[index] >= 2 || _isComplete) return;
    setState(() => _groupCounts[index]++);
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < _groupCounts.length; i++) {
        _groupCounts[i] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const instruction = SupportLine(
      japanese: 'いちごを、3人に2こずつ分けてみよう。',
      ruby: 'いちごを、3{人|にん}に2こずつ{分|わ}けてみよう。',
      native: {
        AppLanguage.portuguese:
            'Vamos dividir os morangos: 2 para cada uma das 3 pessoas.',
        AppLanguage.tagalog:
            'Hatiin natin ang strawberry: 2 para sa bawat isa sa 3 tao.',
        AppLanguage.vietnamese:
            'Hãy chia dâu: mỗi người trong 3 người được 2 quả.',
      },
    );

    return Column(
      children: [
        _SupportedInstruction(
          line: instruction,
          language: widget.language,
          showNative: _showInstructionNative,
          onToggleNative: () =>
              setState(() => _showInstructionNative = !_showInstructionNative),
          vocabularyEntries: _remainderLearnVocabulary,
        ),
        const SizedBox(height: 14),
        _RemainderStrawberrySource(remainingCount: _remainingCount),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _groupCounts.length; i++)
                  SizedBox(
                    width: compact ? 142 : 176,
                    child: _RemainderDropTarget(
                      index: i + 1,
                      count: _groupCounts[i],
                      acceptsStrawberry: _groupCounts[i] < 2 && !_isComplete,
                      onAccept: () => _placeStrawberry(i),
                    ),
                  ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _LearnIconButton(
            semanticLabel: 'もう一度',
            icon: Icons.refresh_rounded,
            onPressed: _placedCount == 0 ? null : _reset,
          ),
        ),
        if (_isComplete) ...[
          const SizedBox(height: 10),
          _RemainderShareResult(
            language: widget.language,
            showNative: _showResultNative,
            onToggleNative: () =>
                setState(() => _showResultNative = !_showResultNative),
          ),
        ],
      ],
    );
  }
}

class _RemainderStrawberrySource extends StatelessWidget {
  final int remainingCount;

  const _RemainderStrawberrySource({required this.remainingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 102),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DEE8)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              remainingCount == 1 ? 'のこったいちご 1こ' : 'いちご ${remainingCount}こ',
              style: const TextStyle(
                fontFamily: AppFonts.interface,
                color: Color(0xFF374151),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              for (var i = 0; i < remainingCount; i++)
                Draggable<int>(
                  data: i,
                  feedback: const Material(
                    color: Colors.transparent,
                    child: _CounterDot(size: 42),
                  ),
                  childWhenDragging: const Opacity(
                    opacity: 0.2,
                    child: _CounterDot(size: 42),
                  ),
                  child: const _CounterDot(size: 42),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single, neutral plate surface shared by the division activities.
/// Keeping the food directly on the plate makes the destination clear without
/// turning each person's area into a large coloured number box.
class _SharingPlate extends StatelessWidget {
  final List<Widget> children;
  final double itemExtent;
  final bool active;
  final Color? rimColor;

  const _SharingPlate({
    required this.children,
    required this.itemExtent,
    this.active = false,
    this.rimColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 8,
              bottom: 2,
              child: CustomPaint(
                painter: rimColor == null
                    ? _PlatePainter(active: active)
                    : _SharingPlatePainter(rimColor: rimColor!),
              ),
            ),
            Positioned(
              top: 0,
              child: SizedBox(
                width: itemExtent * 2 + 8,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: children,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SharingPlatePainter extends CustomPainter {
  final Color rimColor;

  const _SharingPlatePainter({required this.rimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final outerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.86,
      height: size.height * 0.58,
    );
    final innerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.61,
      height: size.height * 0.32,
    );
    canvas.drawOval(outerRect, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawOval(
      outerRect,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      innerRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SharingPlatePainter oldDelegate) {
    return oldDelegate.rimColor != rimColor;
  }
}

class _RemainderDropTarget extends StatelessWidget {
  final int index;
  final int count;
  final bool acceptsStrawberry;
  final VoidCallback onAccept;

  const _RemainderDropTarget({
    required this.index,
    required this.count,
    required this.acceptsStrawberry,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAccept: (_) => acceptsStrawberry,
      onAccept: (_) => onAccept(),
      builder: (context, candidateData, _) {
        final active = candidateData.isNotEmpty && acceptsStrawberry;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 154,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? const Color(0xFF60A5FA) : const Color(0xFFD1D5DB),
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$index人目',
                    style: const TextStyle(
                      fontFamily: AppFonts.interface,
                      color: Color(0xFF334155),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: _SharingPlate(
                  active: active,
                  itemExtent: 40,
                  children: [
                    for (var i = 0; i < count; i++) const _CounterDot(size: 40),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              _PlateProgressLabel(count: count, total: 2),
              const SizedBox(height: 2),
            ],
          ),
        );
      },
    );
  }
}

class _PlateProgressLabel extends StatelessWidget {
  final int count;
  final int total;

  const _PlateProgressLabel({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$count / $total',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.interface,
          color: Color(0xFF1F2937),
          fontSize: 17,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RemainderShareResult extends StatelessWidget {
  final AppLanguage language;
  final bool showNative;
  final VoidCallback onToggleNative;

  const _RemainderShareResult({
    required this.language,
    required this.showNative,
    required this.onToggleNative,
  });

  @override
  Widget build(BuildContext context) {
    const line = SupportLine(
      japanese: '3人に2こずつ分けると、1こ残りました。この1こを「あまり」といいます。',
      ruby: '3{人|にん}に2こずつ{分|わ}けると、1こ{残|のこ}りました。この1こを「あまり」といいます。',
      native: {
        AppLanguage.portuguese:
            'Ao dividir 2 para cada uma das 3 pessoas, sobrou 1. Esse 1 é o resto.',
        AppLanguage.tagalog:
            'Nang bigyan ng 2 ang bawat isa sa 3 tao, 1 ang natira. Iyon ang sobra.',
        AppLanguage.vietnamese:
            'Chia 2 cho mỗi người trong 3 người thì còn 1. Đó là số dư.',
      },
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 24,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '同じ数ずつ分けられたね！',
                  style: TextStyle(
                    fontFamily: AppFonts.interface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
              _IconSupportActions(
                language: language,
                showNative: showNative,
                translateLabel: showNative ? '日本語で見る' : '${language.label}で見る',
                audioLabel: 'あまりの説明の音声',
                onToggleNative: onToggleNative,
                onAudio: () => LearningAudio.speakJapanese(
                  context,
                  label: 'あまりの説明',
                  text: line.japanese,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LargeEquation(
            parts: const [
              _EquationPart('7', Color(0xFF2563EB), 'ぜんぶの数'),
              _EquationPart('÷', Color(0xFF111827), ''),
              _EquationPart('3', Color(0xFFF97316), '人数'),
              _EquationPart('=', Color(0xFF111827), ''),
              _EquationPart('2', Color(0xFF059669), '1人分'),
              _EquationPart('あまり', Color(0xFF111827), ''),
              _EquationPart('1', Color(0xFFB45309), 'あまり'),
            ],
          ),
          const SizedBox(height: 12),
          _SupportedTextLines(
            lines: const [line],
            language: language,
            showNative: showNative,
            vocabularyEntries: _remainderLearnVocabulary,
            enableLearningSupport: true,
          ),
        ],
      ),
    );
  }
}

class _RemainderEquationBuilder extends StatefulWidget {
  final AppLanguage language;

  const _RemainderEquationBuilder({required this.language});

  @override
  State<_RemainderEquationBuilder> createState() =>
      _RemainderEquationBuilderState();
}

class _RemainderEquationBuilderState extends State<_RemainderEquationBuilder> {
  int? _each;
  int? _remainder;
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  bool get _complete => _each == 2 && _remainder == 1;

  @override
  Widget build(BuildContext context) {
    const instruction = SupportLine(
      japanese: 'お皿のいちごを見て、式の□に入る数を選ぼう。',
      ruby: '{皿|さら}のいちごを{見|み}て、{式|しき}の□に{入|はい}る{数|かず}を{選|えら}ぼう。',
      native: {
        AppLanguage.portuguese:
            'Observe os morangos nos pratos e escolha os números para os quadrados.',
        AppLanguage.tagalog:
            'Tingnan ang strawberry sa mga plato at piliin ang mga numero para sa mga parisukat.',
        AppLanguage.vietnamese:
            'Nhìn dâu trên đĩa và chọn số điền vào ô vuông.',
      },
    );
    return Column(
      children: [
        _SupportedInstruction(
          line: instruction,
          language: widget.language,
          showNative: _showInstructionNative,
          onToggleNative: () =>
              setState(() => _showInstructionNative = !_showInstructionNative),
          vocabularyEntries: _remainderLearnVocabulary,
        ),
        const SizedBox(height: 16),
        _RemainderMiniDiagram(each: 2, remainder: 1),
        const SizedBox(height: 16),
        _LargeEquation(
          parts: [
            const _EquationPart('7', Color(0xFF2563EB), 'ぜんぶの数'),
            const _EquationPart('÷', Color(0xFF111827), ''),
            const _EquationPart('3', Color(0xFFF97316), '人数'),
            const _EquationPart('=', Color(0xFF111827), ''),
            _EquationPart(
              _each?.toString() ?? '□',
              const Color(0xFF059669),
              '1人分',
              boxed: true,
            ),
            const _EquationPart('あまり', Color(0xFF111827), ''),
            _EquationPart(
              _remainder?.toString() ?? '□',
              const Color(0xFFB45309),
              'あまり',
              boxed: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _RemainderValueRow(
          label: '1人分',
          color: const Color(0xFF059669),
          values: const [1, 2, 3],
          selected: _each,
          onSelected: (value) => setState(() => _each = value),
        ),
        const SizedBox(height: 10),
        _RemainderValueRow(
          label: 'あまり',
          color: const Color(0xFFB45309),
          values: const [0, 1, 2],
          selected: _remainder,
          onSelected: (value) => setState(() => _remainder = value),
        ),
        if ((_each != null || _remainder != null) && !_complete) ...[
          const SizedBox(height: 12),
          const Text(
            'お皿の中と、残っているいちごをもう一度見てみよう。',
            style: TextStyle(
              fontFamily: AppFonts.interface,
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_complete) ...[
          const SizedBox(height: 16),
          _RemainderGreenExplanation(
            language: widget.language,
            showNative: _showResultNative,
            onToggleNative: () =>
                setState(() => _showResultNative = !_showResultNative),
            japanese: '1人分は2こ、残ったのは1こ。だから、7 ÷ 3 = 2 あまり 1 と書きます。',
            ruby:
                '{1人|ひとり}{分|ぶん}は2こ、{残|のこ}ったのは1こ。だから、7 ÷ 3 = 2 あまり 1 と{書|か}きます。',
            portuguese:
                'Cada pessoa recebe 2 e sobra 1. Por isso escrevemos 7 ÷ 3 = 2, resto 1.',
            tagalog:
                '2 ang sa bawat tao at 1 ang natira. Kaya sinusulat natin 7 ÷ 3 = 2, sobra 1.',
            vietnamese:
                'Mỗi người được 2, còn dư 1. Vì vậy viết 7 ÷ 3 = 2 dư 1.',
          ),
        ],
      ],
    );
  }
}

class _RemainderValueButton extends StatelessWidget {
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const _RemainderValueButton({
    required this.value,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          fixedSize: const Size(62, 52),
          padding: EdgeInsets.zero,
          backgroundColor: selected
              ? color.withValues(alpha: 0.10)
              : Colors.white,
          side: BorderSide(
            color: selected ? color : const Color(0xFFD7DEE8),
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: selected ? color : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _RemainderValueRow extends StatelessWidget {
  final String label;
  final Color color;
  final List<int> values;
  final int? selected;
  final ValueChanged<int> onSelected;

  const _RemainderValueRow({
    required this.label,
    required this.color,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFonts.interface,
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final value in values)
          _RemainderValueButton(
            value: value,
            color: color,
            selected: selected == value,
            onPressed: () => onSelected(value),
          ),
      ],
    );
  }
}

class _RemainderTimesTableFinder extends StatefulWidget {
  final AppLanguage language;

  const _RemainderTimesTableFinder({required this.language});

  @override
  State<_RemainderTimesTableFinder> createState() =>
      _RemainderTimesTableFinderState();
}

class _RemainderTimesTableFinderState
    extends State<_RemainderTimesTableFinder> {
  int? _selected;
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  @override
  Widget build(BuildContext context) {
    const instruction = SupportLine(
      japanese: '7をこえない、いちばん大きい3のだんを選ぼう。',
      ruby: '7をこえない、いちばん{大|おお}きい3のだんを{選|えら}ぼう。',
      native: {
        AppLanguage.portuguese:
            'Escolha a maior conta da tabuada do 3 que não passa de 7.',
        AppLanguage.tagalog:
            'Piliin ang pinakamalaking 3-times table na hindi lalampas ng 7.',
        AppLanguage.vietnamese:
            'Chọn phép nhân 3 lớn nhất mà không vượt quá 7.',
      },
    );
    final correct = _selected == 2;
    return Column(
      children: [
        _SupportedInstruction(
          line: instruction,
          language: widget.language,
          showNative: _showInstructionNative,
          onToggleNative: () =>
              setState(() => _showInstructionNative = !_showInstructionNative),
          vocabularyEntries: _remainderLearnVocabulary,
        ),
        const SizedBox(height: 16),
        const Text(
          '3 × □ + 1 = 7',
          style: TextStyle(
            fontFamily: AppFonts.display,
            color: Color(0xFF111827),
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final item in const [(1, 3), (2, 6), (3, 9)])
              _TimesTableChoice(
                factor: item.$1,
                result: item.$2,
                selected: _selected == item.$1,
                onPressed: () => setState(() => _selected = item.$1),
              ),
          ],
        ),
        if (_selected != null && !correct) ...[
          const SizedBox(height: 14),
          const Text(
            '7より大きくならないか、たしかめてみよう。',
            style: TextStyle(
              fontFamily: AppFonts.interface,
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (correct) ...[
          const SizedBox(height: 16),
          _RemainderGreenExplanation(
            language: widget.language,
            showNative: _showResultNative,
            onToggleNative: () =>
                setState(() => _showResultNative = !_showResultNative),
            japanese: '3 × 2 = 6です。7から6を使うと、1こ残ります。だから、7 ÷ 3 = 2 あまり 1です。',
            ruby:
                '3 × 2 = 6です。7から6を{使|つか}うと、1こ{残|のこ}ります。だから、7 ÷ 3 = 2 あまり 1です。',
            portuguese:
                '3 × 2 = 6. Ao usar 6 dos 7, sobra 1. Por isso, 7 ÷ 3 = 2, resto 1.',
            tagalog:
                '3 × 2 = 6. Kapag ginamit ang 6 mula sa 7, 1 ang natira. Kaya 7 ÷ 3 = 2, sobra 1.',
            vietnamese:
                '3 × 2 = 6. Lấy 6 trong 7 thì còn 1. Vì vậy 7 ÷ 3 = 2 dư 1.',
          ),
        ],
      ],
    );
  }
}

class _TimesTableChoice extends StatelessWidget {
  final int factor;
  final int result;
  final bool selected;
  final VoidCallback onPressed;

  const _TimesTableChoice({
    required this.factor,
    required this.result,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(152, 78),
        backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF60A5FA) : const Color(0xFFD7DEE8),
          width: selected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        '3 × $factor = $result',
        style: const TextStyle(
          fontFamily: AppFonts.display,
          color: Color(0xFF111827),
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RemainderGrowthExplorer extends StatefulWidget {
  final AppLanguage language;

  const _RemainderGrowthExplorer({required this.language});

  @override
  State<_RemainderGrowthExplorer> createState() =>
      _RemainderGrowthExplorerState();
}

class _RemainderGrowthExplorerState extends State<_RemainderGrowthExplorer> {
  int _total = 6;
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  int get _each => _total ~/ 3;
  int get _remainder => _total % 3;

  @override
  Widget build(BuildContext context) {
    const instruction = SupportLine(
      japanese: 'いちごを1こずつ増やして、あまりがどうなるか見てみよう。',
      ruby: 'いちごを1こずつ{増|ふ}やして、あまりがどうなるか{見|み}てみよう。',
      native: {
        AppLanguage.portuguese:
            'Acrescente um morango de cada vez e veja o que acontece com o resto.',
        AppLanguage.tagalog:
            'Dagdagan ng isang strawberry sa bawat pagkakataon at tingnan ang sobra.',
        AppLanguage.vietnamese:
            'Thêm từng quả dâu một và xem số dư thay đổi thế nào.',
      },
    );
    final reachedNine = _total == 9;
    return Column(
      children: [
        _SupportedInstruction(
          line: instruction,
          language: widget.language,
          showNative: _showInstructionNative,
          onToggleNative: () =>
              setState(() => _showInstructionNative = !_showInstructionNative),
          vocabularyEntries: _remainderLearnVocabulary,
        ),
        const SizedBox(height: 16),
        _RemainderMiniDiagram(each: _each, remainder: _remainder),
        const SizedBox(height: 12),
        Text(
          '$_total ÷ 3 = $_each あまり $_remainder',
          style: const TextStyle(
            fontFamily: AppFonts.display,
            color: Color(0xFF111827),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: reachedNine ? null : () => setState(() => _total++),
          icon: const Icon(Icons.add_rounded),
          label: const Text('いちごを1こ増やす'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(210, 48),
          ),
        ),
        if (reachedNine) ...[
          const SizedBox(height: 16),
          _RemainderGreenExplanation(
            language: widget.language,
            showNative: _showResultNative,
            onToggleNative: () =>
                setState(() => _showResultNative = !_showResultNative),
            japanese: 'あまりが3こになる前に、3人にもう1こずつ分けられました。あまりは、わる数の3より小さくなります。',
            ruby:
                'あまりが3こになる{前|まえ}に、3{人|にん}にもう1こずつ{分|わ}けられました。あまりは、{わる数|わる かず}の3より{小|ちい}さくなります。',
            portuguese:
                'Antes de o resto chegar a 3, conseguimos dar mais 1 para cada uma das 3 pessoas. O resto é menor que 3.',
            tagalog:
                'Bago maging 3 ang sobra, nakapagbigay pa tayo ng 1 sa bawat isa sa 3 tao. Mas maliit sa 3 ang sobra.',
            vietnamese:
                'Trước khi số dư thành 3, ta còn chia thêm 1 cho mỗi người trong 3 người. Số dư nhỏ hơn 3.',
          ),
        ],
      ],
    );
  }
}

class _RemainderMiniDiagram extends StatelessWidget {
  final int each;
  final int remainder;

  const _RemainderMiniDiagram({required this.each, required this.remainder});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < 3; i++)
          _RemainderVisualGroup(label: '${i + 1}人目', count: each),
        if (remainder > 0)
          _RemainderVisualGroup(
            label: 'あまり',
            count: remainder,
            isRemainder: true,
          ),
      ],
    );
  }
}

class _RemainderVisualGroup extends StatelessWidget {
  final String label;
  final int count;
  final bool isRemainder;

  const _RemainderVisualGroup({
    required this.label,
    required this.count,
    this.isRemainder = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRemainder
        ? const Color(0xFFFDE68A)
        : const Color(0xFFD1D5DB);
    final background = isRemainder ? const Color(0xFFFFFBEB) : Colors.white;
    final textColor = isRemainder
        ? const Color(0xFF92400E)
        : const Color(0xFF065F46);
    return Container(
      width: 142,
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.interface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 74,
            child: _SharingPlate(
              itemExtent: 31,
              rimColor: isRemainder
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFFCBD5E1),
              children: [
                for (var i = 0; i < count; i++) const _CounterDot(size: 31),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainderGreenExplanation extends StatelessWidget {
  final AppLanguage language;
  final bool showNative;
  final VoidCallback onToggleNative;
  final String japanese;
  final String ruby;
  final String portuguese;
  final String tagalog;
  final String vietnamese;

  const _RemainderGreenExplanation({
    required this.language,
    required this.showNative,
    required this.onToggleNative,
    required this.japanese,
    required this.ruby,
    required this.portuguese,
    required this.tagalog,
    required this.vietnamese,
  });

  @override
  Widget build(BuildContext context) {
    final line = SupportLine(
      japanese: japanese,
      ruby: ruby,
      native: {
        AppLanguage.portuguese: portuguese,
        AppLanguage.tagalog: tagalog,
        AppLanguage.vietnamese: vietnamese,
      },
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            // Ruby sits above the main glyphs, so align this with the text itself.
            padding: EdgeInsets.only(top: 8),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SupportedTextLines(
              lines: [line],
              language: language,
              showNative: showNative,
              vocabularyEntries: _remainderLearnVocabulary,
              enableLearningSupport: true,
            ),
          ),
          const SizedBox(width: 8),
          _IconSupportActions(
            language: language,
            showNative: showNative,
            translateLabel: showNative ? '日本語で見る' : '${language.label}で見る',
            audioLabel: '説明の音声',
            onToggleNative: onToggleNative,
            onAudio: () => LearningAudio.speakJapanese(
              context,
              label: 'あまりの説明',
              text: japanese,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainderSummaryPanel extends StatelessWidget {
  const _RemainderSummaryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 ÷ 3 = 2 あまり 1',
            style: TextStyle(
              fontFamily: AppFonts.display,
              color: Color(0xFF111827),
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '3 × 2 + 1 = 7',
            style: TextStyle(
              fontFamily: AppFonts.display,
              color: Color(0xFF065F46),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenchRemainderDiagram extends StatelessWidget {
  final int benchCount;
  final bool showWaiting;
  final AppLanguage selectedLanguage;

  const _BenchRemainderDiagram({
    required this.benchCount,
    required this.showWaiting,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return _BenchSeatingActivity(
      key: ValueKey('bench-seating-$benchCount-$showWaiting'),
      benchCount: benchCount,
      selectedLanguage: selectedLanguage,
    );
  }
}

class _BenchSeatingActivity extends StatefulWidget {
  final int benchCount;
  final AppLanguage selectedLanguage;

  const _BenchSeatingActivity({
    super.key,
    required this.benchCount,
    required this.selectedLanguage,
  });

  @override
  State<_BenchSeatingActivity> createState() => _BenchSeatingActivityState();
}

class _BenchSeatingActivityState extends State<_BenchSeatingActivity> {
  static const int _personCount = 9;
  late List<int?> _seats;
  bool _showInstructionNative = false;

  @override
  void initState() {
    super.initState();
    _seats = List<int?>.filled(_personCount, null);
  }

  int get _capacity => widget.benchCount * 4;

  bool get _hasUnseatedRemainder =>
      widget.benchCount == 2 && _seatedCount == _capacity;

  bool get _isComplete =>
      widget.benchCount == 3 && _seatedCount == _personCount;

  int get _seatedCount => _seats.whereType<int>().length;

  List<int> _peopleForBench(int benchIndex) {
    return [
      for (var i = 0; i < _seats.length; i++)
        if (_seats[i] == benchIndex) i,
    ];
  }

  List<int> get _unseatedPeople {
    return [
      for (var i = 0; i < _seats.length; i++)
        if (_seats[i] == null) i,
    ];
  }

  bool _canSitOnBench(int benchIndex) {
    return _peopleForBench(benchIndex).length < 4;
  }

  void _seatPerson(int personIndex, int benchIndex) {
    if (!_canSitOnBench(benchIndex)) return;
    setState(() => _seats[personIndex] = benchIndex);
  }

  void _reset() {
    setState(() => _seats = List<int?>.filled(_personCount, null));
  }

  String get _instructionTranslation {
    final isFirstTry = widget.benchCount == 2;
    return switch (widget.selectedLanguage) {
      AppLanguage.portuguese =>
        isFirstTry
            ? 'Primeiro, vamos sentar em 2 bancos!'
            : 'Agora, vamos sentar em 3 bancos!',
      AppLanguage.tagalog =>
        isFirstTry
            ? 'Subukan muna nating umupo sa 2 bangko!'
            : 'Ngayon, subukan nating umupo sa 3 bangko!',
      AppLanguage.vietnamese =>
        isFirstTry
            ? 'Truoc het, hay ngoi tren 2 chiec ghe bang!'
            : 'Bay gio, hay ngoi tren 3 chiec ghe bang!',
      AppLanguage.japanese => '',
    };
  }

  Widget _buildInstruction(BuildContext context) {
    final isFirstTry = widget.benchCount == 2;
    final instruction = isFirstTry ? 'まずは2台にすわらせてみよう！' : '3台にすわらせてみよう！';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(
                    fontFamily: AppFonts.interface,
                    color: Color(0xFF1E3A8A),
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_showInstructionNative &&
                    _instructionTranslation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _instructionTranslation,
                    style: const TextStyle(
                      fontFamily: AppFonts.interface,
                      color: Color(0xFF475569),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconSupportActions(
            language: widget.selectedLanguage,
            showNative: _showInstructionNative,
            translateLabel: widget.selectedLanguage.label,
            audioLabel: '操作の音声',
            onToggleNative: () {
              setState(() => _showInstructionNative = !_showInstructionNative);
            },
            onAudio: () => LearningAudio.speakJapanese(
              context,
              label: '操作の案内',
              text: instruction,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInstruction(context),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PersonPool(
                people: _unseatedPeople,
                showSadRemainder: _hasUnseatedRemainder,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final benchWidth = availableWidth < 620
                      ? availableWidth
                      : availableWidth < 920
                      ? (availableWidth - 12) / 2
                      : 280.0;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < widget.benchCount; i++)
                        SizedBox(
                          width: benchWidth,
                          child: _BenchDropBox(
                            index: i + 1,
                            people: _peopleForBench(i),
                            onAccept: (personIndex) =>
                                _seatPerson(personIndex, i),
                            canAccept: _canSitOnBench(i),
                            allSeated: _isComplete,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _LearnIconButton(
            semanticLabel: 'もう一度',
            icon: Icons.refresh_rounded,
            onPressed: _reset,
          ),
        ),
        if (_hasUnseatedRemainder || _isComplete) ...[
          const SizedBox(height: 12),
          _BenchResultMessage(
            isComplete: _isComplete,
            language: widget.selectedLanguage,
          ),
        ],
      ],
    );
  }
}

class _PersonPool extends StatelessWidget {
  final List<int> people;
  final bool showSadRemainder;

  const _PersonPool({required this.people, required this.showSadRemainder});

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const SizedBox(height: 72);
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final person in people)
          _DraggablePerson(
            personIndex: person,
            isSad: showSadRemainder && people.length == 1,
          ),
      ],
    );
  }
}

class _DraggablePerson extends StatelessWidget {
  final int personIndex;
  final bool isSad;

  const _DraggablePerson({required this.personIndex, required this.isSad});

  @override
  Widget build(BuildContext context) {
    final child = _IllustratedPerson(
      personIndex: personIndex,
      mood: isSad ? _PersonMood.sad : _PersonMood.neutral,
      size: 68,
    );
    return Draggable<int>(
      data: personIndex,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.08, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: child,
    );
  }
}

class _BenchDropBox extends StatelessWidget {
  final int index;
  final List<int> people;
  final ValueChanged<int> onAccept;
  final bool canAccept;
  final bool allSeated;

  const _BenchDropBox({
    required this.index,
    required this.people,
    required this.onAccept,
    required this.canAccept,
    required this.allSeated,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => canAccept,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        final isActive = candidates.isNotEmpty && canAccept;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index台目',
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 144,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    const Positioned(
                      bottom: 4,
                      left: 2,
                      right: 2,
                      child: _LongBenchIllustration(),
                    ),
                    Positioned(
                      bottom: 70,
                      left: 4,
                      right: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var slot = 0; slot < 4; slot++)
                            if (slot < people.length)
                              _IllustratedPerson(
                                personIndex: people[slot],
                                mood: allSeated
                                    ? _PersonMood.happy
                                    : _PersonMood.neutral,
                                size: 44,
                              )
                            else
                              const SizedBox(width: 44, height: 44),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LongBenchIllustration extends StatelessWidget {
  const _LongBenchIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _LongBenchPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LongBenchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final seat = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.03,
        size.height * 0.30,
        size.width * 0.94,
        size.height * 0.20,
      ),
      Radius.circular(size.height * 0.08),
    );
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.07,
        size.height * 0.12,
        size.width * 0.86,
        size.height * 0.17,
      ),
      Radius.circular(size.height * 0.07),
    );
    final legPaint = Paint()
      ..color = const Color(0xFF8B5E34)
      ..strokeWidth = math.max(4, size.height * 0.07)
      ..strokeCap = StrokeCap.round;
    final backPaint = Paint()..color = const Color(0xFFD6A25E);
    final seatPaint = Paint()..color = const Color(0xFFB7793D);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(back, backPaint);
    canvas.drawRRect(seat, seatPaint);
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.52),
      Offset(size.width * 0.14, size.height * 0.92),
      legPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.52),
      Offset(size.width * 0.86, size.height * 0.92),
      legPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.9),
      Offset(size.width * 0.30, size.height * 0.9),
      legPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.9),
      Offset(size.width * 0.86, size.height * 0.9),
      legPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.38),
      Offset(size.width * 0.88, size.height * 0.38),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _PersonMood { neutral, happy, sad }

class _IllustratedPerson extends StatelessWidget {
  final int personIndex;
  final _PersonMood mood;
  final double size;

  const _IllustratedPerson({
    required this.personIndex,
    required this.mood,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PersonPainter(
          palette: _PersonPalette.forIndex(personIndex),
          mood: mood,
        ),
      ),
    );
  }
}

class _PersonPalette {
  final Color skin;
  final Color hair;
  final Color shirt;
  final int hairStyle;

  const _PersonPalette({
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.hairStyle,
  });

  static _PersonPalette forIndex(int index) {
    const palettes = [
      _PersonPalette(
        skin: Color(0xFFE8B58D),
        hair: Color(0xFF3A2417),
        shirt: Color(0xFF2563EB),
        hairStyle: 0,
      ),
      _PersonPalette(
        skin: Color(0xFF8D5A3B),
        hair: Color(0xFF171717),
        shirt: Color(0xFF059669),
        hairStyle: 3,
      ),
      _PersonPalette(
        skin: Color(0xFFF2C9A5),
        hair: Color(0xFF6B3F22),
        shirt: Color(0xFFE11D48),
        hairStyle: 4,
      ),
      _PersonPalette(
        skin: Color(0xFFB77955),
        hair: Color(0xFF211812),
        shirt: Color(0xFFF59E0B),
        hairStyle: 1,
      ),
      _PersonPalette(
        skin: Color(0xFFF3D7BE),
        hair: Color(0xFFB45309),
        shirt: Color(0xFF7C3AED),
        hairStyle: 2,
      ),
      _PersonPalette(
        skin: Color(0xFFD39B74),
        hair: Color(0xFF1F2937),
        shirt: Color(0xFF0891B2),
        hairStyle: 5,
      ),
      _PersonPalette(
        skin: Color(0xFF6F4632),
        hair: Color(0xFF111827),
        shirt: Color(0xFFDC2626),
        hairStyle: 3,
      ),
      _PersonPalette(
        skin: Color(0xFFF0BE96),
        hair: Color(0xFF4B5563),
        shirt: Color(0xFF65A30D),
        hairStyle: 0,
      ),
      _PersonPalette(
        skin: Color(0xFFC9825A),
        hair: Color(0xFF2F1F16),
        shirt: Color(0xFF0F766E),
        hairStyle: 5,
      ),
    ];
    return palettes[index % palettes.length];
  }
}

class _PersonPainter extends CustomPainter {
  final _PersonPalette palette;
  final _PersonMood mood;

  const _PersonPainter({required this.palette, required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final skinPaint = Paint()..color = palette.skin;
    final hairPaint = Paint()..color = palette.hair;
    final shirtPaint = Paint()..color = palette.shirt;
    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.10);
    final cheekPaint = Paint()
      ..color = const Color(0xFFEF7C8E).withOpacity(0.34);
    final neckPaint = Paint()
      ..color = Color.lerp(palette.skin, const Color(0xFF8B4513), 0.10)!;
    final linePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = math.max(1.5, w * 0.032)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final softLinePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = math.max(1.1, w * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.94),
        width: w * 0.62,
        height: h * 0.10,
      ),
      shadowPaint,
    );

    final bodyPath = Path()
      ..moveTo(cx - w * 0.27, h * 0.67)
      ..quadraticBezierTo(cx - w * 0.36, h * 0.82, cx - w * 0.26, h * 0.96)
      ..lineTo(cx + w * 0.26, h * 0.96)
      ..quadraticBezierTo(cx + w * 0.36, h * 0.82, cx + w * 0.27, h * 0.67)
      ..quadraticBezierTo(cx, h * 0.58, cx - w * 0.27, h * 0.67)
      ..close();
    final leftArmPath = Path()
      ..moveTo(cx - w * 0.23, h * 0.70)
      ..cubicTo(
        cx - w * 0.32,
        h * 0.72,
        cx - w * 0.42,
        h * 0.78,
        cx - w * 0.49,
        h * 0.88,
      )
      ..cubicTo(
        cx - w * 0.45,
        h * 0.94,
        cx - w * 0.38,
        h * 0.94,
        cx - w * 0.34,
        h * 0.88,
      )
      ..cubicTo(
        cx - w * 0.30,
        h * 0.80,
        cx - w * 0.22,
        h * 0.76,
        cx - w * 0.13,
        h * 0.72,
      )
      ..close();
    final rightArmPath = Path()
      ..moveTo(cx + w * 0.23, h * 0.70)
      ..cubicTo(
        cx + w * 0.32,
        h * 0.72,
        cx + w * 0.42,
        h * 0.78,
        cx + w * 0.49,
        h * 0.88,
      )
      ..cubicTo(
        cx + w * 0.45,
        h * 0.94,
        cx + w * 0.38,
        h * 0.94,
        cx + w * 0.34,
        h * 0.88,
      )
      ..cubicTo(
        cx + w * 0.30,
        h * 0.80,
        cx + w * 0.22,
        h * 0.76,
        cx + w * 0.13,
        h * 0.72,
      )
      ..close();
    canvas.drawPath(leftArmPath, shirtPaint);
    canvas.drawPath(rightArmPath, shirtPaint);
    canvas.drawPath(bodyPath, shirtPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.44, h * 0.89),
        width: w * 0.10,
        height: h * 0.08,
      ),
      skinPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.44, h * 0.89),
        width: w * 0.10,
        height: h * 0.08,
      ),
      skinPaint,
    );

    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.63),
        width: w * 0.17,
        height: h * 0.15,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(neck, neckPaint);

    final backHairPath = Path();
    if (palette.hairStyle == 2) {
      backHairPath
        ..moveTo(cx - w * 0.31, h * 0.66)
        ..lineTo(cx - w * 0.31, h * 0.30)
        ..cubicTo(
          cx - w * 0.29,
          h * 0.10,
          cx - w * 0.12,
          h * 0.06,
          cx,
          h * 0.07,
        )
        ..cubicTo(
          cx + w * 0.16,
          h * 0.06,
          cx + w * 0.31,
          h * 0.16,
          cx + w * 0.31,
          h * 0.31,
        )
        ..lineTo(cx + w * 0.31, h * 0.66)
        ..quadraticBezierTo(cx + w * 0.25, h * 0.74, cx + w * 0.17, h * 0.73)
        ..lineTo(cx - w * 0.17, h * 0.73)
        ..quadraticBezierTo(cx - w * 0.25, h * 0.74, cx - w * 0.31, h * 0.66)
        ..close();
      canvas.drawPath(backHairPath, hairPaint);
    } else if (palette.hairStyle == 3) {
      backHairPath
        ..moveTo(cx - w * 0.34, h * 0.49)
        ..cubicTo(
          cx - w * 0.45,
          h * 0.40,
          cx - w * 0.42,
          h * 0.22,
          cx - w * 0.28,
          h * 0.19,
        )
        ..cubicTo(
          cx - w * 0.26,
          h * 0.06,
          cx - w * 0.08,
          h * 0.03,
          cx + w * 0.01,
          h * 0.10,
        )
        ..cubicTo(
          cx + w * 0.13,
          h * 0.03,
          cx + w * 0.31,
          h * 0.10,
          cx + w * 0.30,
          h * 0.22,
        )
        ..cubicTo(
          cx + w * 0.43,
          h * 0.28,
          cx + w * 0.43,
          h * 0.44,
          cx + w * 0.33,
          h * 0.51,
        )
        ..lineTo(cx + w * 0.25, h * 0.64)
        ..lineTo(cx - w * 0.25, h * 0.64)
        ..close();
      canvas.drawPath(backHairPath, hairPaint);
    } else if (palette.hairStyle == 5) {
      // A single, continuous long-hair silhouette reads more naturally at
      // this small scale than separate lock strokes.
      backHairPath
        ..moveTo(cx - w * 0.30, h * 0.69)
        ..lineTo(cx - w * 0.30, h * 0.30)
        ..cubicTo(
          cx - w * 0.28,
          h * 0.12,
          cx - w * 0.11,
          h * 0.07,
          cx,
          h * 0.08,
        )
        ..cubicTo(
          cx + w * 0.15,
          h * 0.07,
          cx + w * 0.30,
          h * 0.16,
          cx + w * 0.30,
          h * 0.31,
        )
        ..lineTo(cx + w * 0.30, h * 0.69)
        ..quadraticBezierTo(cx + w * 0.22, h * 0.73, cx + w * 0.15, h * 0.70)
        ..lineTo(cx - w * 0.15, h * 0.70)
        ..quadraticBezierTo(cx - w * 0.22, h * 0.73, cx - w * 0.30, h * 0.69)
        ..close();
      canvas.drawPath(backHairPath, hairPaint);
    }

    final faceRect = Rect.fromCenter(
      center: Offset(cx, h * 0.39),
      width: w * 0.48,
      height: h * 0.52,
    );
    canvas.drawOval(faceRect, skinPaint);

    final hairPath = Path();
    final leftTemple = cx - w * 0.24;
    final rightTemple = cx + w * 0.24;
    final faceTop = faceRect.top;
    final hairLine = h * 0.34;
    if (palette.hairStyle == 0) {
      hairPath
        ..moveTo(leftTemple, h * 0.36)
        ..cubicTo(
          leftTemple,
          faceTop + h * 0.04,
          cx - w * 0.10,
          faceTop - h * 0.02,
          cx + w * 0.05,
          faceTop + h * 0.01,
        )
        ..cubicTo(
          rightTemple,
          faceTop + h * 0.04,
          rightTemple,
          h * 0.23,
          rightTemple,
          h * 0.39,
        )
        ..cubicTo(
          cx + w * 0.10,
          hairLine,
          cx - w * 0.08,
          h * 0.31,
          leftTemple,
          h * 0.36,
        )
        ..close();
    } else if (palette.hairStyle == 1) {
      hairPath
        ..moveTo(leftTemple - w * 0.02, h * 0.36)
        ..cubicTo(
          leftTemple,
          faceTop + h * 0.03,
          cx - w * 0.08,
          faceTop - h * 0.02,
          cx,
          faceTop + h * 0.02,
        )
        ..cubicTo(
          cx + w * 0.12,
          faceTop - h * 0.01,
          rightTemple,
          faceTop + h * 0.04,
          rightTemple + w * 0.02,
          h * 0.37,
        )
        ..cubicTo(
          cx + w * 0.11,
          h * 0.32,
          cx - w * 0.10,
          h * 0.32,
          leftTemple - w * 0.02,
          h * 0.36,
        )
        ..close();
    } else if (palette.hairStyle == 2) {
      hairPath
        ..moveTo(leftTemple - w * 0.04, h * 0.40)
        ..cubicTo(
          leftTemple - w * 0.02,
          h * 0.24,
          cx - w * 0.15,
          faceTop - h * 0.03,
          cx + w * 0.03,
          faceTop - h * 0.04,
        )
        ..cubicTo(
          cx + w * 0.18,
          faceTop - h * 0.03,
          rightTemple + w * 0.04,
          h * 0.22,
          rightTemple + w * 0.04,
          h * 0.40,
        )
        ..cubicTo(
          cx + w * 0.14,
          h * 0.34,
          cx - w * 0.11,
          h * 0.33,
          leftTemple - w * 0.04,
          h * 0.40,
        )
        ..close();
    } else if (palette.hairStyle == 3) {
      hairPath
        ..moveTo(leftTemple - w * 0.05, h * 0.41)
        ..cubicTo(
          leftTemple - w * 0.02,
          h * 0.22,
          cx - w * 0.16,
          faceTop - h * 0.04,
          cx,
          faceTop - h * 0.05,
        )
        ..cubicTo(
          cx + w * 0.19,
          faceTop - h * 0.04,
          rightTemple + w * 0.07,
          h * 0.22,
          rightTemple + w * 0.05,
          h * 0.42,
        )
        ..cubicTo(
          cx + w * 0.11,
          h * 0.35,
          cx - w * 0.11,
          h * 0.35,
          leftTemple - w * 0.05,
          h * 0.41,
        )
        ..close();
    } else if (palette.hairStyle == 4) {
      hairPath
        ..moveTo(leftTemple - w * 0.03, h * 0.39)
        ..cubicTo(
          leftTemple - w * 0.01,
          h * 0.20,
          cx - w * 0.16,
          faceTop - h * 0.03,
          cx + w * 0.02,
          faceTop - h * 0.04,
        )
        ..cubicTo(
          cx + w * 0.17,
          faceTop - h * 0.03,
          rightTemple + w * 0.07,
          h * 0.22,
          rightTemple + w * 0.04,
          h * 0.39,
        )
        ..cubicTo(
          cx + w * 0.12,
          h * 0.33,
          cx - w * 0.06,
          h * 0.34,
          leftTemple - w * 0.03,
          h * 0.39,
        )
        ..close();
    } else if (palette.hairStyle == 5) {
      hairPath
        ..moveTo(leftTemple - w * 0.04, h * 0.40)
        ..cubicTo(
          leftTemple - w * 0.01,
          h * 0.23,
          cx - w * 0.10,
          faceTop - h * 0.04,
          cx,
          faceTop - h * 0.04,
        )
        ..cubicTo(
          cx + w * 0.11,
          faceTop - h * 0.04,
          rightTemple + w * 0.04,
          h * 0.23,
          rightTemple + w * 0.04,
          h * 0.40,
        )
        ..cubicTo(
          cx + w * 0.12,
          h * 0.34,
          cx - w * 0.12,
          h * 0.34,
          leftTemple - w * 0.04,
          h * 0.40,
        )
        ..close();
    } else {
      hairPath
        ..moveTo(leftTemple - w * 0.04, h * 0.40)
        ..cubicTo(
          leftTemple - w * 0.02,
          h * 0.20,
          cx - w * 0.15,
          faceTop - h * 0.03,
          cx + w * 0.04,
          faceTop - h * 0.04,
        )
        ..cubicTo(
          cx + w * 0.19,
          faceTop - h * 0.03,
          rightTemple + w * 0.07,
          h * 0.22,
          rightTemple + w * 0.05,
          h * 0.40,
        )
        ..cubicTo(
          cx + w * 0.10,
          h * 0.34,
          cx - w * 0.09,
          h * 0.33,
          leftTemple - w * 0.04,
          h * 0.40,
        )
        ..close();
    }
    canvas.drawPath(hairPath, hairPaint);
    if (palette.hairStyle == 1) {
      canvas.drawLine(
        Offset(cx, h * 0.15),
        Offset(cx, h * 0.31),
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = math.max(1, w * 0.018)
          ..strokeCap = StrokeCap.round,
      );
    }

    final eyePaint = Paint()..color = const Color(0xFF111827);
    canvas.drawCircle(Offset(cx - w * 0.09, h * 0.42), w * 0.023, eyePaint);
    canvas.drawCircle(Offset(cx + w * 0.09, h * 0.42), w * 0.023, eyePaint);
    canvas.drawCircle(Offset(cx - w * 0.16, h * 0.48), w * 0.035, cheekPaint);
    canvas.drawCircle(Offset(cx + w * 0.16, h * 0.48), w * 0.035, cheekPaint);

    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.16, h * 0.36)
        ..quadraticBezierTo(cx - w * 0.08, h * 0.32, cx - w * 0.02, h * 0.35),
      softLinePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + w * 0.02, h * 0.35)
        ..quadraticBezierTo(cx + w * 0.10, h * 0.32, cx + w * 0.17, h * 0.36),
      softLinePaint,
    );

    final mouthPath = Path();
    if (mood == _PersonMood.happy) {
      mouthPath.moveTo(cx - w * 0.10, h * 0.53);
      mouthPath.quadraticBezierTo(cx, h * 0.62, cx + w * 0.10, h * 0.53);
    } else if (mood == _PersonMood.sad) {
      mouthPath.moveTo(cx - w * 0.10, h * 0.58);
      mouthPath.quadraticBezierTo(cx, h * 0.49, cx + w * 0.10, h * 0.58);
      final tearPaint = Paint()..color = const Color(0xFF60A5FA);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + w * 0.16, h * 0.50),
          width: w * 0.045,
          height: h * 0.075,
        ),
        tearPaint,
      );
    } else {
      mouthPath.moveTo(cx - w * 0.08, h * 0.54);
      mouthPath.quadraticBezierTo(cx, h * 0.57, cx + w * 0.08, h * 0.54);
    }
    canvas.drawPath(mouthPath, linePaint);

    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.14, h * 0.78)
        ..quadraticBezierTo(cx, h * 0.84, cx + w * 0.14, h * 0.78),
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..strokeWidth = math.max(1.1, w * 0.025)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PersonPainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.mood != mood;
  }
}

class _BenchResultMessage extends StatefulWidget {
  final bool isComplete;
  final AppLanguage language;

  const _BenchResultMessage({required this.isComplete, required this.language});

  @override
  State<_BenchResultMessage> createState() => _BenchResultMessageState();
}

class _BenchResultMessageState extends State<_BenchResultMessage> {
  bool _showNative = false;

  String get _japaneseText {
    return widget.isComplete
        ? '3台にすると、9人みんなすわれます。'
        : '2台では8人までなので、1人がまだすわれません。';
  }

  String get _nativeText {
    return switch (widget.language) {
      AppLanguage.portuguese =>
        widget.isComplete
            ? 'Com 3 bancos, as 9 pessoas conseguem se sentar.'
            : 'Com 2 bancos, cabem 8 pessoas. Ainda falta 1 pessoa sentar.',
      AppLanguage.tagalog =>
        widget.isComplete
            ? 'Sa 3 bangko, makakaupo ang lahat ng 9 na tao.'
            : 'Hanggang 8 tao ang makakaupo sa 2 bangko. May 1 tao pang hindi makaupo.',
      AppLanguage.vietnamese =>
        widget.isComplete
            ? 'Voi 3 ghe bang, ca 9 nguoi deu ngoi duoc.'
            : 'Hai ghe bang chi du cho 8 nguoi. Con 1 nguoi chua ngoi duoc.',
      AppLanguage.japanese => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.interface,
      color: widget.isComplete
          ? const Color(0xFF047857)
          : const Color(0xFF92400E),
      fontSize: 21,
      height: 1.45,
      fontWeight: FontWeight.w800,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isComplete
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isComplete) ...[
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_japaneseText, style: style),
                if (_showNative && _nativeText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _nativeText,
                    style: const TextStyle(
                      fontFamily: AppFonts.interface,
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconSupportActions(
            language: widget.language,
            showNative: _showNative,
            translateLabel: widget.language.label,
            audioLabel: '結果の音声',
            onToggleNative: () => setState(() => _showNative = !_showNative),
            onAudio: () => LearningAudio.speakJapanese(
              context,
              label: '結果の説明',
              text: _japaneseText,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainderContextSummaryPanel extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _RemainderContextSummaryPanel({required this.selectedLanguage});

  @override
  State<_RemainderContextSummaryPanel> createState() =>
      _RemainderContextSummaryPanelState();
}

class _RemainderContextSummaryPanelState
    extends State<_RemainderContextSummaryPanel> {
  bool _showNative = false;

  static const _conclusionLine = SupportLine(
    japanese: '2台では1人すわれないので、答えは3台です。',
    ruby: '2{台|だい}では1{人|ひとり}すわれないので、{答|こた}えは3{台|だい}です。',
    native: {
      AppLanguage.portuguese:
          'Com 2 bancos, 1 pessoa ainda não consegue sentar. Por isso, a resposta é 3 bancos.',
      AppLanguage.tagalog:
          'Sa 2 bangko, may 1 tao pang hindi makaupo. Kaya 3 bangko ang sagot.',
      AppLanguage.vietnamese:
          'Voi 2 ghe bang, van con 1 nguoi chua ngoi duoc. Vi vay, dap an la 3 ghe bang.',
    },
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  '9 ÷ 4 = 2 あまり 1',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _IconSupportActions(
                language: widget.selectedLanguage,
                showNative: _showNative,
                translateLabel: _showNative
                    ? '日本語で見る'
                    : '${widget.selectedLanguage.label}で見る',
                audioLabel: 'まとめの音声',
                onToggleNative: () {
                  setState(() => _showNative = !_showNative);
                },
                onAudio: () => LearningAudio.speakJapanese(
                  context,
                  label: 'まとめの説明',
                  text: _conclusionLine.japanese,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RubyText(
            text: _conclusionLine.rubyText,
            vocabularyEntries: _remainderContextVocabulary,
            language: widget.selectedLanguage,
            enableLearningSupport: true,
            style: const TextStyle(
              color: Color(0xFF065F46),
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_showNative &&
              widget.selectedLanguage != AppLanguage.japanese &&
              _conclusionLine
                  .nativeFor(widget.selectedLanguage)
                  .isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _conclusionLine.nativeFor(widget.selectedLanguage),
              style: const TextStyle(
                fontFamily: AppFonts.interface,
                color: Color(0xFF047857),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LearnTextBlock extends StatelessWidget {
  final List<SupportLine> lines;
  final AppLanguage language;
  final bool showNative;

  const _LearnTextBlock({
    required this.lines,
    required this.language,
    required this.showNative,
  });

  @override
  Widget build(BuildContext context) {
    return _SupportedTextLines(
      lines: lines,
      language: language,
      showNative: showNative,
      vocabularyEntries: _divisionMultiplicationVocabulary,
      enableLearningSupport: true,
    );
  }
}

const _divisionMultiplicationVocabulary = [
  VocabularyEntry(
    term: '答え',
    reading: 'こたえ',
    simpleJapanese: '計算して出した数です。',
    translations: {
      AppLanguage.portuguese: 'resposta',
      AppLanguage.tagalog: 'sagot',
      AppLanguage.vietnamese: 'đáp án',
    },
    exampleSentence: 'わり算の答えを見つけます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'かけ算',
    reading: 'かけざん',
    simpleJapanese: '同じ数を何回分か合わせる計算です。',
    translations: {
      AppLanguage.portuguese: 'multiplicação',
      AppLanguage.tagalog: 'multiplication',
      AppLanguage.vietnamese: 'phép nhân',
    },
    exampleSentence: 'かけ算を使って考えます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '式',
    reading: 'しき',
    simpleJapanese: '計算を、数字や記号で書いたものです。',
    translations: {
      AppLanguage.portuguese: 'conta / expressão',
      AppLanguage.tagalog: 'pahayag sa matematika',
      AppLanguage.vietnamese: 'phép tính',
    },
    exampleSentence: '2つの式を見ます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '全部',
    reading: 'ぜんぶ',
    simpleJapanese: 'あるものをすべて合わせた数です。',
    translations: {
      AppLanguage.portuguese: 'total / tudo',
      AppLanguage.tagalog: 'kabuuan',
      AppLanguage.vietnamese: 'tất cả',
    },
    exampleSentence: '全部で12こです。',
    category: 'math_language',
  ),
];

class _InteractiveCookieShare extends StatefulWidget {
  final AppLanguage language;

  const _InteractiveCookieShare({required this.language});

  @override
  State<_InteractiveCookieShare> createState() =>
      _InteractiveCookieShareState();
}

class _InteractiveCookieShareState extends State<_InteractiveCookieShare> {
  final List<int> _groupCounts = List<int>.filled(3, 0);
  bool _showMultiplication = false;
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  int get _placedCount => _groupCounts.fold(0, (sum, count) => sum + count);
  int get _remainingCount => 12 - _placedCount;
  bool get _isComplete =>
      _remainingCount == 0 && _groupCounts.every((count) => count == 4);

  void _placeCookie(int groupIndex) {
    if (_groupCounts[groupIndex] >= 4 || _remainingCount == 0) return;
    setState(() => _groupCounts[groupIndex]++);
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < _groupCounts.length; i++) {
        _groupCounts[i] = 0;
      }
      _showMultiplication = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const instruction = SupportLine(
      japanese: 'クッキーを、1人分ずつ4こになるように運ぼう。',
      ruby: 'クッキーを、{1人|ひとり}{分|ぶん}ずつ4こになるように{運|はこ}ぼう。',
      native: {
        AppLanguage.portuguese:
            'Leve os biscoitos para que cada pessoa fique com 4.',
        AppLanguage.tagalog:
            'Dalhin ang mga biskwit para 4 ang maging bahagi ng bawat tao.',
        AppLanguage.vietnamese:
            'Chuyển bánh quy sao cho mỗi người có 4 cái.',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SupportedInstruction(
          line: instruction,
          language: widget.language,
          showNative: _showInstructionNative,
          onToggleNative: () {
            setState(() => _showInstructionNative = !_showInstructionNative);
          },
          vocabularyEntries: _divisionMultiplicationVocabulary,
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            _InteractiveCookieSource(remainingCount: _remainingCount),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < _groupCounts.length; i++)
                      SizedBox(
                        width: compact ? 148 : 180,
                        child: _InteractiveCookieTarget(
                          index: i + 1,
                          count: _groupCounts[i],
                          acceptsCookie:
                              _groupCounts[i] < 4 && _remainingCount > 0,
                          onAccept: () => _placeCookie(i),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _LearnIconButton(
                semanticLabel: 'もう一度',
                icon: Icons.refresh_rounded,
                onPressed: _placedCount == 0 ? null : _reset,
              ),
            ),
          ],
        ),
        if (_isComplete) ...[
          const SizedBox(height: 14),
          _InteractiveCookieResult(
            language: widget.language,
            showNative: _showResultNative,
            showMultiplication: _showMultiplication,
            onToggleNative: () {
              setState(() => _showResultNative = !_showResultNative);
            },
            onSelectMultiplication: (selected) {
              setState(() => _showMultiplication = selected);
            },
          ),
        ],
      ],
    );
  }
}

class _InteractiveCookieResult extends StatelessWidget {
  final AppLanguage language;
  final bool showNative;
  final bool showMultiplication;
  final VoidCallback onToggleNative;
  final ValueChanged<bool> onSelectMultiplication;

  const _InteractiveCookieResult({
    required this.language,
    required this.showNative,
    required this.showMultiplication,
    required this.onToggleNative,
    required this.onSelectMultiplication,
  });

  @override
  Widget build(BuildContext context) {
    final explanation = showMultiplication
        ? const SupportLine(
            japanese: '4こずつが3人分あるから、3 × 4 = 12。',
            ruby: '4こずつが3{人|にん}{分|ぶん}あるから、3 × 4 = 12。',
            native: {
              AppLanguage.portuguese:
                  'Há 3 pessoas com 4 biscoitos cada uma, por isso 3 × 4 = 12.',
              AppLanguage.tagalog:
                  'May 3 tao na tig-4 na biskwit, kaya 3 × 4 = 12.',
              AppLanguage.vietnamese:
                  'Có 3 người, mỗi người 4 cái bánh, nên 3 × 4 = 12.',
            },
          )
        : const SupportLine(
            japanese: '12こを3人で分けたから、12 ÷ 3 = 4。',
            ruby: '12こを3{人|にん}で{分けた|わけた}から、12 ÷ 3 = 4。',
            native: {
              AppLanguage.portuguese:
                  'Dividimos 12 biscoitos entre 3 pessoas, por isso 12 ÷ 3 = 4.',
              AppLanguage.tagalog:
                  'Hinati ang 12 biskwit sa 3 tao, kaya 12 ÷ 3 = 4.',
              AppLanguage.vietnamese:
                  'Chia 12 cái bánh cho 3 người, nên 12 ÷ 3 = 4.',
            },
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '3人に4こずつ分けられたね。',
                  style: TextStyle(
                    fontFamily: AppFonts.interface,
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
              _IconSupportActions(
                language: language,
                showNative: showNative,
                translateLabel: showNative ? '日本語で見る' : '${language.label}で見る',
                audioLabel: '説明の音声',
                onToggleNative: onToggleNative,
                onAudio: () => LearningAudio.speakJapanese(
                  context,
                  label: '分け方の説明',
                  text: '3人に4こずつ分けられたね。${explanation.japanese}',
                ),
              ),
            ],
          ),
          if (showNative && language != AppLanguage.japanese) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                language == AppLanguage.portuguese
                    ? 'Conseguimos dividir 4 biscoitos para cada pessoa.'
                    : '',
                style: const TextStyle(
                  fontFamily: AppFonts.interface,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF047857),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('わり算で見る'),
                selected: !showMultiplication,
                onSelected: (_) => onSelectMultiplication(false),
                showCheckmark: true,
                checkmarkColor: const Color(0xFF047857),
                backgroundColor: const Color(0xFFF0FDF4),
                selectedColor: const Color(0xFFD1FAE5),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
                labelStyle: const TextStyle(
                  fontFamily: AppFonts.interface,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
              ChoiceChip(
                label: const Text('かけ算で見る'),
                selected: showMultiplication,
                onSelected: (_) => onSelectMultiplication(true),
                showCheckmark: true,
                checkmarkColor: const Color(0xFF1D4ED8),
                backgroundColor: const Color(0xFFEFF6FF),
                selectedColor: const Color(0xFFDBEAFE),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                labelStyle: const TextStyle(
                  fontFamily: AppFonts.interface,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LargeEquation(
            parts: showMultiplication
                ? const [
                    _EquationPart('3', Color(0xFFF97316), '人数'),
                    _EquationPart('×', Color(0xFF111827), ''),
                    _EquationPart('4', Color(0xFF059669), '1人分'),
                    _EquationPart('=', Color(0xFF111827), ''),
                    _EquationPart('12', Color(0xFF2563EB), 'ぜんぶの数'),
                  ]
                : const [
                    _EquationPart('12', Color(0xFF2563EB), 'ぜんぶの数'),
                    _EquationPart('÷', Color(0xFF111827), ''),
                    _EquationPart('3', Color(0xFFF97316), '人数'),
                    _EquationPart('=', Color(0xFF111827), ''),
                    _EquationPart('4', Color(0xFF059669), '1人分'),
                  ],
          ),
          const SizedBox(height: 10),
          _SupportedTextLines(
            lines: [explanation],
            language: language,
            showNative: showNative,
            vocabularyEntries: _divisionMultiplicationVocabulary,
            enableLearningSupport: true,
          ),
        ],
      ),
    );
  }
}

class _InteractiveCookieSource extends StatelessWidget {
  final int remainingCount;

  const _InteractiveCookieSource({required this.remainingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: remainingCount == 0
          ? const Center(
              child: Text(
                'ぜんぶ分けられたね！',
                style: TextStyle(
                  fontFamily: AppFonts.interface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            )
          : Center(
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < remainingCount; i++)
                    Draggable<int>(
                      data: i,
                      feedback: const Material(
                        color: Colors.transparent,
                        child: _CookieDot(size: 36),
                      ),
                      childWhenDragging: const Opacity(
                        opacity: 0.25,
                        child: _CookieDot(size: 36),
                      ),
                      child: const _CookieDot(size: 36),
                    ),
                ],
              ),
            ),
    );
  }
}

class _InteractiveCookieTarget extends StatelessWidget {
  final int index;
  final int count;
  final bool acceptsCookie;
  final VoidCallback onAccept;

  const _InteractiveCookieTarget({
    required this.index,
    required this.count,
    required this.acceptsCookie,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAccept: (_) => acceptsCookie,
      onAccept: (_) => onAccept(),
      builder: (context, candidateData, _) {
        final isTargeted = candidateData.isNotEmpty && acceptsCookie;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints.tightFor(height: 154),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTargeted ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isTargeted
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFFD1D5DB),
              width: isTargeted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$index人目',
                    style: const TextStyle(
                      fontFamily: AppFonts.interface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: _SharingPlate(
                  active: isTargeted,
                  itemExtent: 32,
                  children: [
                    for (var i = 0; i < count; i++) const _CookieDot(size: 32),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              _PlateProgressLabel(count: count, total: 4),
              const SizedBox(height: 2),
            ],
          ),
        );
      },
    );
  }
}

class _CookieShareDiagram extends StatelessWidget {
  final int total;
  final int groups;
  final int each;

  const _CookieShareDiagram({
    required this.total,
    required this.groups,
    required this.each,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CookieRow(count: total),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < groups; i++)
                    SizedBox(
                      width: compact ? 150 : 180,
                      child: _CookiePersonBox(index: i + 1, count: each),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookieRow extends StatelessWidget {
  final int count;

  const _CookieRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [for (var i = 0; i < count; i++) const _CookieDot()],
      ),
    );
  }
}

class _CookiePersonBox extends StatelessWidget {
  final int index;
  final int count;

  const _CookiePersonBox({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: Color(0xFF64748B),
                size: 17,
              ),
              const SizedBox(width: 4),
              Text(
                '$index人目',
                style: const TextStyle(
                  fontFamily: AppFonts.interface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 66,
            child: _SharingPlate(
              itemExtent: 28,
              children: [
                for (var i = 0; i < count; i++) const _CookieDot(size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CookieDot extends StatelessWidget {
  final double size;

  const _CookieDot({this.size = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _CookieDotPainter()),
    );
  }
}

class _CookieDotPainter extends CustomPainter {
  const _CookieDotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    canvas.drawCircle(
      center.translate(0, 1.2),
      radius,
      Paint()
        ..color = const Color(0x220F172A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: const [
            Color(0xFFFFE8A3),
            Color(0xFFF59E0B),
            Color(0xFFB45309),
          ],
          stops: [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x70FFFFFF)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    final chipPaint = Paint()..color = const Color(0xFF7C2D12);
    for (final p in const [
      Offset(0.35, 0.35),
      Offset(0.58, 0.33),
      Offset(0.7, 0.53),
      Offset(0.47, 0.62),
      Offset(0.31, 0.68),
    ]) {
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        radius * 0.13,
        chipPaint,
      );
    }
    canvas.drawCircle(
      center.translate(-radius * 0.34, -radius * 0.32),
      radius * 0.16,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _CookieDotPainter oldDelegate) => false;
}

class _EquationPart {
  final String text;
  final Color color;
  final String label;
  final String? nativeLabel;
  final bool boxed;

  const _EquationPart(
    this.text,
    this.color,
    this.label, {
    this.nativeLabel,
    this.boxed = false,
  });
}

class _LargeEquation extends StatelessWidget {
  final List<_EquationPart> parts;
  final bool showNative;

  const _LargeEquation({required this.parts, this.showNative = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final part in parts)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (part.boxed)
                Text(
                  part.text,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 36,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: part.color,
                  ),
                )
              else
                Text(
                  part.text,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: part.label.isEmpty ? 28 : 34,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: part.color,
                  ),
                ),
              if (part.label.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: part.color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  part.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: part.color,
                  ),
                ),
                if (showNative && part.nativeLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    part.nativeLabel!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: part.color.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ],
            ],
          ),
      ],
    );
  }
}

class _EquationPairPanel extends StatefulWidget {
  final AppLanguage language;

  const _EquationPairPanel({required this.language});

  @override
  State<_EquationPairPanel> createState() => _EquationPairPanelState();
}

class _EquationPairPanelState extends State<_EquationPairPanel> {
  bool _showNative = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LargeEquation(
                  showNative: _showNative,
                  parts: const [
                    _EquationPart(
                      '12',
                      Color(0xFF2563EB),
                      'ぜんぶの数',
                      nativeLabel: 'total',
                    ),
                    _EquationPart('÷', Color(0xFF111827), ''),
                    _EquationPart(
                      '3',
                      Color(0xFFF97316),
                      '人数',
                      nativeLabel: 'pessoas',
                    ),
                    _EquationPart('=', Color(0xFF111827), ''),
                    _EquationPart(
                      '4',
                      Color(0xFF059669),
                      '1人分',
                      nativeLabel: 'por pessoa',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _LargeEquation(
                  showNative: _showNative,
                  parts: const [
                    _EquationPart(
                      '3',
                      Color(0xFFF97316),
                      '人数',
                      nativeLabel: 'pessoas',
                    ),
                    _EquationPart('×', Color(0xFF111827), ''),
                    _EquationPart(
                      '4',
                      Color(0xFF059669),
                      '1人分',
                      nativeLabel: 'por pessoa',
                    ),
                    _EquationPart('=', Color(0xFF111827), ''),
                    _EquationPart(
                      '12',
                      Color(0xFF2563EB),
                      'ぜんぶの数',
                      nativeLabel: 'total',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconSupportActions(
            language: widget.language,
            showNative: _showNative,
            translateLabel: '翻訳',
            audioLabel: '音声',
            onToggleNative: () {
              setState(() => _showNative = !_showNative);
            },
            onAudio: () => LearningAudio.speakJapanese(
              context,
              label: '式の数の役割',
              text: '12はぜんぶの数、3は人数、4は1人分です。',
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroOneDivisionLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;

  const _ZeroOneDivisionLearn({required this.selectedLanguage});

  @override
  State<_ZeroOneDivisionLearn> createState() => _ZeroOneDivisionLearnState();
}

class _ZeroOneDivisionLearnState extends State<_ZeroOneDivisionLearn> {
  int _scenarioIndex = 0;
  bool _showResult = false;
  bool _showProblemNative = false;
  bool _showInstructionNative = false;
  bool _showResultNative = false;
  final List<int?> _berryOwners = List<int?>.filled(6, null);

  _ZeroOneScenario get _scenario => _zeroOneScenarios[_scenarioIndex];

  void _selectScenario(int index) {
    setState(() {
      _scenarioIndex = index;
      _showResult = false;
      _showInstructionNative = false;
      _showResultNative = false;
      for (var i = 0; i < _berryOwners.length; i++) {
        _berryOwners[i] = null;
      }
    });
  }

  void _moveBerry(int berryIndex, int? targetIndex) {
    setState(() {
      _berryOwners[berryIndex] = targetIndex;
      if (_scenario.kind == _ZeroOneScenarioKind.divideByOne &&
          _berryOwners.every((owner) => owner == 0)) {
        _showResult = true;
      }
    });
  }

  void _resetScenario() {
    setState(() {
      _showResult = false;
      for (var i = 0; i < _berryOwners.length; i++) {
        _berryOwners[i] = null;
      }
    });
  }

  List<int> get _sourceBerryIds {
    return [
      for (var i = 0; i < _scenario.totalCount; i++)
        if (_berryOwners[i] == null) i,
    ];
  }

  List<List<int>> get _targetBerryIds {
    return [
      for (var target = 0; target < _scenario.personCount; target++)
        [
          for (var i = 0; i < _scenario.totalCount; i++)
            if (_berryOwners[i] == target) i,
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowResult =
        _showResult || _scenario.kind != _ZeroOneScenarioKind.divideByOne;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LearnHeaderIcon(icon: Icons.calculate_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '0や1を使ったわり算',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SupportedTextLines(
                            lines: [_scenario.problemLine],
                            language: widget.selectedLanguage,
                            showNative: _showProblemNative,
                            vocabularyEntries: zeroOneDivisionVocabularyEntries,
                            enableLearningSupport: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _IconSupportActions(
                          language: widget.selectedLanguage,
                          showNative: _showProblemNative,
                          translateLabel: _showProblemNative
                              ? '日本語で見る'
                              : '${widget.selectedLanguage.label}で見る',
                          audioLabel: '問題文の音声',
                          onToggleNative: () {
                            setState(() {
                              _showProblemNative = !_showProblemNative;
                            });
                          },
                          onAudio: () => LearningAudio.speakJapanese(
                            context,
                            label: '問題文',
                            text: _scenario.problem,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ZeroOneScenarioTabs(
            selectedIndex: _scenarioIndex,
            onChanged: _selectScenario,
          ),
          const SizedBox(height: 16),
          _ZeroOneDragBoard(
            key: ValueKey('drag-$_scenarioIndex'),
            scenario: _scenario,
            sourceBerryIds: _sourceBerryIds,
            targetBerryIds: _targetBerryIds,
            showResult: _showResult,
            selectedLanguage: widget.selectedLanguage,
            showInstructionNative: _showInstructionNative,
            onToggleInstructionNative: () {
              setState(() {
                _showInstructionNative = !_showInstructionNative;
              });
            },
            onMoveBerry: _moveBerry,
            onReset: _resetScenario,
          ),
          const SizedBox(height: 14),
          if (shouldShowResult) ...[
            _ZeroOneResultPanel(
              scenario: _scenario,
              selectedLanguage: widget.selectedLanguage,
              showNative: _showResultNative,
              onToggleNative: () {
                setState(() {
                  _showResultNative = !_showResultNative;
                });
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

enum _ZeroOneScenarioKind { divideByOne, zeroDivided, divideByZero }

class _ZeroOneScenario {
  final _ZeroOneScenarioKind kind;
  final String tabLabel;
  final SupportLine problemLine;
  final int totalCount;
  final int personCount;
  final SupportLine instructionLine;
  final SupportLine storyHintLine;
  final String equation;
  final SupportLine explanationLine;
  final SupportLine ruleLine;
  final int maxStoryStep;

  const _ZeroOneScenario({
    required this.kind,
    required this.tabLabel,
    required this.problemLine,
    required this.totalCount,
    required this.personCount,
    required this.instructionLine,
    required this.storyHintLine,
    required this.equation,
    required this.explanationLine,
    required this.ruleLine,
    required this.maxStoryStep,
  });

  String get problem => problemLine.japanese;
  String get instruction => instructionLine.japanese;
  String get storyHint => storyHintLine.japanese;
  String get explanation => explanationLine.japanese;
  String get rule => ruleLine.japanese;
}

const _zeroOneScenarios = [
  _ZeroOneScenario(
    kind: _ZeroOneScenarioKind.divideByOne,
    tabLabel: '1でわる',
    problemLine: SupportLine(
      japanese: 'いちごが6こあります。1人で同じ数ずつ分けると、1人分は何こになりますか。',
      ruby:
          'いちごが6こあります。{1人|ひとり}で{同じ数ずつ|おなじかずずつ}{分ける|わける}と、{1人|ひとり}{分|ぶん}は{何|なん}こになりますか。',
      native: {
        AppLanguage.portuguese:
            'Há 6 morangos. Se dividirmos igualmente com 1 pessoa, quantos morangos essa pessoa recebe?',
        AppLanguage.tagalog:
            'May 6 na strawberry. Kung hahatiin nang pantay sa 1 tao, ilan ang para sa taong iyon?',
        AppLanguage.vietnamese:
            'Có 6 quả dâu. Nếu chia đều cho 1 người, người đó nhận bao nhiêu quả?',
      },
    ),
    totalCount: 6,
    personCount: 1,
    instructionLine: SupportLine(
      japanese: 'いちごを、1人のお皿へ動かしてみよう。',
      ruby: 'いちごを、{1人|ひとり}のお{皿|さら}へ{動|うご}かしてみよう。',
      native: {
        AppLanguage.portuguese:
            'Vamos mover os morangos para o prato de 1 pessoa.',
        AppLanguage.tagalog:
            'Ilipat natin ang mga strawberry sa plato ng 1 tao.',
        AppLanguage.vietnamese: 'Hãy chuyển dâu vào đĩa của 1 người.',
      },
    ),
    storyHintLine: SupportLine(
      japanese: '1人だけなので、いちごは全部その人のところへ行きます。',
      ruby: '{1人|ひとり}だけなので、いちごは{全部|ぜんぶ}その{人|ひと}のところへ{行|い}きます。',
      native: {
        AppLanguage.portuguese:
            'Como há apenas 1 pessoa, todos os morangos vão para essa pessoa.',
        AppLanguage.tagalog:
            'Dahil 1 tao lang, lahat ng strawberry ay mapupunta sa taong iyon.',
        AppLanguage.vietnamese:
            'Vì chỉ có 1 người, tất cả dâu sẽ đến người đó.',
      },
    ),
    equation: '6 ÷ 1 = 6',
    explanationLine: SupportLine(
      japanese: '1人で分けるので、6このいちごは全部その人がもらいます。だから、1人分は6こです。',
      ruby:
          '{1人|ひとり}で{分ける|わける}ので、6このいちごは{全部|ぜんぶ}その{人|ひと}がもらいます。だから、{1人|ひとり}{分|ぶん}は6こです。',
      native: {
        AppLanguage.portuguese:
            'Como dividimos com 1 pessoa, essa pessoa recebe todos os 6 morangos. Então, a parte de 1 pessoa é 6.',
        AppLanguage.tagalog:
            'Dahil hinahati sa 1 tao, makukuha niya ang lahat ng 6 na strawberry. Kaya ang para sa 1 tao ay 6.',
        AppLanguage.vietnamese:
            'Vì chia cho 1 người, người đó nhận tất cả 6 quả dâu. Vậy phần của 1 người là 6 quả.',
      },
    ),
    ruleLine: SupportLine(
      japanese: '1でわると、答えはもとの数になります。',
      ruby: '1でわると、{答え|こたえ}はもとの{数|かず}になります。',
      native: {
        AppLanguage.portuguese:
            'Quando dividimos por 1, a resposta é o número original.',
        AppLanguage.tagalog:
            'Kapag hinati sa 1, ang sagot ay ang dating bilang.',
        AppLanguage.vietnamese: 'Khi chia cho 1, đáp án là số ban đầu.',
      },
    ),
    maxStoryStep: 3,
  ),
  _ZeroOneScenario(
    kind: _ZeroOneScenarioKind.zeroDivided,
    tabLabel: '0をわる',
    problemLine: SupportLine(
      japanese: 'いちごが0こあります。3人で同じ数ずつ分けると、1人分は何こになりますか。',
      ruby:
          'いちごが0こあります。3{人|にん}で{同じ数ずつ|おなじかずずつ}{分ける|わける}と、{1人|ひとり}{分|ぶん}は{何|なん}こになりますか。',
      native: {
        AppLanguage.portuguese:
            'Há 0 morangos. Se dividirmos igualmente entre 3 pessoas, quantos morangos cada pessoa recebe?',
        AppLanguage.tagalog:
            'May 0 strawberry. Kung hahatiin nang pantay sa 3 tao, ilan ang para sa bawat isa?',
        AppLanguage.vietnamese:
            'Có 0 quả dâu. Nếu chia đều cho 3 người, mỗi người nhận bao nhiêu quả?',
      },
    ),
    totalCount: 0,
    personCount: 3,
    instructionLine: SupportLine(
      japanese: 'いちごは0こです。お皿の数を見てみよう。',
      ruby: 'いちごは0こです。お{皿|さら}の{数|かず}を{見|み}てみよう。',
      native: {
        AppLanguage.portuguese: 'Há 0 morangos. Vamos olhar os pratos.',
        AppLanguage.tagalog: 'May 0 strawberry. Tingnan natin ang mga plato.',
        AppLanguage.vietnamese: 'Có 0 quả dâu. Hãy nhìn các đĩa.',
      },
    ),
    storyHintLine: SupportLine(
      japanese: '配るいちごがないので、どのお皿にも入りません。',
      ruby: '{配|くば}るいちごがないので、どのお{皿|さら}にも{入|はい}りません。',
      native: {
        AppLanguage.portuguese:
            'Não há morangos para distribuir, então nenhum prato recebe morangos.',
        AppLanguage.tagalog:
            'Walang strawberry na ipapamahagi, kaya walang laman ang mga plato.',
        AppLanguage.vietnamese:
            'Không có dâu để chia, nên không đĩa nào có dâu.',
      },
    ),
    equation: '0 ÷ 3 = 0',
    explanationLine: SupportLine(
      japanese: 'いちごは0こなので、配るものがありません。3人のお皿は、どれも0こです。',
      ruby: 'いちごは0こなので、{配る|くばる}ものがありません。3{人|にん}のお{皿|さら}は、どれも0こです。',
      native: {
        AppLanguage.portuguese:
            'Como há 0 morangos, não há nada para distribuir. Os pratos das 3 pessoas ficam com 0.',
        AppLanguage.tagalog:
            'Dahil 0 ang strawberry, walang ipapamahagi. Ang plato ng bawat isa sa 3 tao ay may 0.',
        AppLanguage.vietnamese:
            'Vì có 0 quả dâu, không có gì để chia. Đĩa của cả 3 người đều có 0 quả.',
      },
    ),
    ruleLine: SupportLine(
      japanese: '0を人数でわると、答えは0になります。',
      ruby: '0を{人数|にんずう}でわると、{答え|こたえ}は0になります。',
      native: {
        AppLanguage.portuguese:
            'Quando dividimos 0 pelo número de pessoas, a resposta é 0.',
        AppLanguage.tagalog:
            'Kapag hinati ang 0 sa bilang ng tao, ang sagot ay 0.',
        AppLanguage.vietnamese: 'Khi chia 0 cho số người, đáp án là 0.',
      },
    ),
    maxStoryStep: 2,
  ),
  _ZeroOneScenario(
    kind: _ZeroOneScenarioKind.divideByZero,
    tabLabel: '0ではわれない',
    problemLine: SupportLine(
      japanese: 'いちごが6こあります。0人で同じ数ずつ分けることはできますか。',
      ruby: 'いちごが6こあります。0{人|にん}で{同じ数ずつ|おなじかずずつ}{分ける|わける}ことはできますか。',
      native: {
        AppLanguage.portuguese:
            'Há 6 morangos. É possível dividir igualmente entre 0 pessoas?',
        AppLanguage.tagalog:
            'May 6 na strawberry. Puwede ba itong hatiin nang pantay sa 0 tao?',
        AppLanguage.vietnamese:
            'Có 6 quả dâu. Có thể chia đều cho 0 người không?',
      },
    ),
    totalCount: 6,
    personCount: 0,
    instructionLine: SupportLine(
      japanese: '分ける人がいるか、見てみよう。',
      ruby: '{分|わ}ける{人|ひと}がいるか、{見|み}てみよう。',
      native: {
        AppLanguage.portuguese: 'Vamos ver se há alguém para receber.',
        AppLanguage.tagalog: 'Tingnan natin kung may taong pagbibigyan.',
        AppLanguage.vietnamese: 'Hãy xem có người nào để chia không.',
      },
    ),
    storyHintLine: SupportLine(
      japanese: 'だれに分ければいいの？',
      ruby: 'だれに{分|わ}ければいいの？',
      native: {
        AppLanguage.portuguese: 'Para quem devemos dividir?',
        AppLanguage.tagalog: 'Kanino natin ito hahatiin?',
        AppLanguage.vietnamese: 'Chia cho ai đây?',
      },
    ),
    equation: '6 ÷ 0',
    explanationLine: SupportLine(
      japanese: 'いちごは6こありますが、分ける人が0人です。だれのお皿にも入れられないので、分けることはできません。',
      ruby:
          'いちごは6こありますが、{分ける|わける}{人|ひと}が0{人|にん}です。だれのお{皿|さら}にも{入れられない|いれられない}ので、{分ける|わける}ことはできません。',
      native: {
        AppLanguage.portuguese:
            'Há 6 morangos, mas há 0 pessoas para receber. Não há prato de ninguém, então não é possível dividir.',
        AppLanguage.tagalog:
            'May 6 na strawberry, pero 0 ang taong pagbibigyan. Walang plato na malalagyan, kaya hindi ito mahahati.',
        AppLanguage.vietnamese:
            'Có 6 quả dâu, nhưng có 0 người nhận. Không có đĩa nào để đặt vào, nên không thể chia.',
      },
    ),
    ruleLine: SupportLine(
      japanese: '0ではわることはできません。',
      ruby: '0ではわることはできません。',
      native: {
        AppLanguage.portuguese: 'Não é possível dividir por 0.',
        AppLanguage.tagalog: 'Hindi maaaring hatiin sa 0.',
        AppLanguage.vietnamese: 'Không thể chia cho 0.',
      },
    ),
    maxStoryStep: 2,
  ),
];

class _ZeroOneScenarioTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ZeroOneScenarioTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final children = [
          for (var i = 0; i < _zeroOneScenarios.length; i++)
            _ZeroOneTabButton(
              label: _zeroOneScenarios[i].tabLabel,
              selected: selectedIndex == i,
              onTap: () => onChanged(i),
            ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _ZeroOneTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ZeroOneTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
        foregroundColor: selected
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF374151),
        side: BorderSide(
          color: selected ? const Color(0xFF60A5FA) : const Color(0xFFE5E7EB),
          width: selected ? 1.6 : 1.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ZeroOneDragBoard extends StatelessWidget {
  final _ZeroOneScenario scenario;
  final List<int> sourceBerryIds;
  final List<List<int>> targetBerryIds;
  final bool showResult;
  final AppLanguage selectedLanguage;
  final bool showInstructionNative;
  final VoidCallback onToggleInstructionNative;
  final void Function(int berryIndex, int? targetIndex) onMoveBerry;
  final VoidCallback onReset;

  const _ZeroOneDragBoard({
    super.key,
    required this.scenario,
    required this.sourceBerryIds,
    required this.targetBerryIds,
    required this.showResult,
    required this.selectedLanguage,
    required this.showInstructionNative,
    required this.onToggleInstructionNative,
    required this.onMoveBerry,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ZeroOneInstruction(
          line: showResult
              ? scenario.explanationLine
              : scenario.instructionLine,
          language: selectedLanguage,
          showNative: showInstructionNative,
          onToggleNative: onToggleInstructionNative,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final source = _ZeroOneSourceTray(
              count: scenario.totalCount,
              berryIds: sourceBerryIds,
              onAccept: (id) => onMoveBerry(id, null),
            );
            final targets = _ZeroOneTargetArea(
              scenario: scenario,
              targetBerryIds: targetBerryIds,
              onMoveBerry: onMoveBerry,
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 250, child: source),
                  const SizedBox(width: 14),
                  Expanded(child: targets),
                ],
              );
            }

            return Column(
              children: [source, const SizedBox(height: 12), targets],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _LearnIconButton(
              semanticLabel: 'やり直す',
              icon: Icons.refresh_rounded,
              onPressed: onReset,
            ),
          ],
        ),
      ],
    );
  }
}

class _ZeroOneInstruction extends StatelessWidget {
  final SupportLine line;
  final AppLanguage language;
  final bool showNative;
  final VoidCallback onToggleNative;

  const _ZeroOneInstruction({
    required this.line,
    required this.language,
    required this.showNative,
    required this.onToggleNative,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SupportedTextLines(
              lines: [line],
              language: language,
              showNative: showNative,
              vocabularyEntries: zeroOneDivisionVocabularyEntries,
              learningSupportMode: LearningSupportMode.rubyOnly,
            ),
          ),
          const SizedBox(width: 10),
          _IconSupportActions(
            language: language,
            showNative: showNative,
            translateLabel: showNative ? '日本語で見る' : '${language.label}で見る',
            audioLabel: '操作案内の音声',
            onToggleNative: onToggleNative,
            onAudio: () => LearningAudio.speakJapanese(
              context,
              label: '操作案内',
              text: line.japanese,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroOneSourceTray extends StatelessWidget {
  final int count;
  final List<int> berryIds;
  final ValueChanged<int> onAccept;

  const _ZeroOneSourceTray({
    required this.count,
    required this.berryIds,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 190,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(text: 'いちご $countこ'),
              Expanded(
                child: Center(
                  child: berryIds.isEmpty
                      ? Text(
                          count == 0 ? 'いちごはありません' : ' ',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final id in berryIds) _DraggableBerry(id: id),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZeroOneTargetArea extends StatelessWidget {
  final _ZeroOneScenario scenario;
  final List<List<int>> targetBerryIds;
  final void Function(int berryIndex, int? targetIndex) onMoveBerry;

  const _ZeroOneTargetArea({
    required this.scenario,
    required this.targetBerryIds,
    required this.onMoveBerry,
  });

  @override
  Widget build(BuildContext context) {
    if (scenario.personCount == 0) {
      return Container(
        height: 190,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          'だれに分ければいいの？',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF92400E),
            fontSize: 22,
            height: 1.35,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final children = [
          for (var i = 0; i < scenario.personCount; i++)
            _ZeroOnePlateTarget(
              index: i,
              berryIds: targetBerryIds[i],
              onMoveBerry: onMoveBerry,
            ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ZeroOnePlateTarget extends StatelessWidget {
  final int index;
  final List<int> berryIds;
  final void Function(int berryIndex, int? targetIndex) onMoveBerry;

  const _ZeroOnePlateTarget({
    required this.index,
    required this.berryIds,
    required this.onMoveBerry,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) => onMoveBerry(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 190,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                top: 30,
                child: CustomPaint(painter: _PlatePainter(active: active)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PersonPlateLabel(
                    index: index,
                    language: AppLanguage.japanese,
                    showNative: false,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 68,
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in berryIds) _DraggableBerry(id: id),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(child: _CountBadge(count: berryIds.length)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZeroOneStoryBoard extends StatelessWidget {
  final _ZeroOneScenario scenario;
  final int step;
  final AppLanguage selectedLanguage;
  final bool showInstructionNative;
  final VoidCallback onToggleInstructionNative;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _ZeroOneStoryBoard({
    super.key,
    required this.scenario,
    required this.step,
    required this.selectedLanguage,
    required this.showInstructionNative,
    required this.onToggleInstructionNative,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final showResult = step >= scenario.maxStoryStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ZeroOneInstruction(
          line: showResult ? scenario.explanationLine : scenario.storyHintLine,
          language: selectedLanguage,
          showNative: showInstructionNative,
          onToggleNative: onToggleInstructionNative,
        ),
        const SizedBox(height: 12),
        _ZeroOneStoryScene(scenario: scenario, step: step),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: step == 0 ? null : onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('もどる'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: step == scenario.maxStoryStep ? null : onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'つぎ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ZeroOneStoryScene extends StatelessWidget {
  final _ZeroOneScenario scenario;
  final int step;

  const _ZeroOneStoryScene({required this.scenario, required this.step});

  @override
  Widget build(BuildContext context) {
    final int shownInTarget = switch (scenario.kind) {
      _ZeroOneScenarioKind.divideByOne =>
        step == 0 ? 0 : (step * 2).clamp(0, 6).toInt(),
      _ZeroOneScenarioKind.zeroDivided => 0,
      _ZeroOneScenarioKind.divideByZero => 0,
    };
    final sourceCount = scenario.totalCount - shownInTarget;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final source = _StaticStrawberryBox(
          title: 'いちご ${scenario.totalCount}こ',
          count: sourceCount,
          emptyText: scenario.totalCount == 0 ? 'いちごはありません' : null,
        );
        final target = scenario.personCount == 0
            ? const _NoPeopleBox()
            : _StaticPeopleBoxes(
                personCount: scenario.personCount,
                shownInTarget: shownInTarget,
              );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 250, child: source),
              const SizedBox(width: 14),
              Expanded(child: target),
            ],
          );
        }
        return Column(children: [source, const SizedBox(height: 12), target]);
      },
    );
  }
}

class _StaticStrawberryBox extends StatelessWidget {
  final String title;
  final int count;
  final String? emptyText;

  const _StaticStrawberryBox({
    required this.title,
    required this.count,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: title),
          Expanded(
            child: Center(
              child: count == 0
                  ? Text(
                      emptyText ?? ' ',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < count; i++)
                          const _CounterDot(size: 42),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticPeopleBoxes extends StatelessWidget {
  final int personCount;
  final int shownInTarget;

  const _StaticPeopleBoxes({
    required this.personCount,
    required this.shownInTarget,
  });

  @override
  Widget build(BuildContext context) {
    final perPerson = personCount == 0 ? 0 : shownInTarget ~/ personCount;
    return Row(
      children: [
        for (var i = 0; i < personCount; i++) ...[
          Expanded(
            child: _StaticPersonPlate(index: i, count: perPerson),
          ),
          if (i != personCount - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StaticPersonPlate extends StatelessWidget {
  final int index;
  final int count;

  const _StaticPersonPlate({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            top: 30,
            child: CustomPaint(painter: _PlatePainter(active: false)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PersonPlateLabel(
                index: index,
                language: AppLanguage.japanese,
                showNative: false,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 68,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < count; i++)
                        const _CounterDot(size: 42),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: _CountBadge(count: count)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoPeopleBox extends StatelessWidget {
  const _NoPeopleBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        '人がいません',
        style: TextStyle(
          color: Color(0xFF92400E),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ZeroOneResultPanel extends StatelessWidget {
  final _ZeroOneScenario scenario;
  final AppLanguage selectedLanguage;
  final bool showNative;
  final VoidCallback onToggleNative;

  const _ZeroOneResultPanel({
    required this.scenario,
    required this.selectedLanguage,
    required this.showNative,
    required this.onToggleNative,
  });

  @override
  Widget build(BuildContext context) {
    final cannotDivide = scenario.kind == _ZeroOneScenarioKind.divideByZero;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SupportedTextLines(
                  lines: [scenario.explanationLine],
                  language: selectedLanguage,
                  showNative: showNative,
                  vocabularyEntries: zeroOneDivisionVocabularyEntries,
                  enableLearningSupport: true,
                ),
              ),
              const SizedBox(width: 10),
              _IconSupportActions(
                language: selectedLanguage,
                showNative: showNative,
                translateLabel: showNative
                    ? '日本語で見る'
                    : '${selectedLanguage.label}で見る',
                audioLabel: '説明の音声',
                onToggleNative: onToggleNative,
                onAudio: () => LearningAudio.speakJapanese(
                  context,
                  label: '説明',
                  text: scenario.explanation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cannotDivide)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  scenario.equation,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Icon(Icons.arrow_forward_rounded),
                ),
                const Text(
                  '答えはありません',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            )
          else
            Text(
              scenario.equation,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: 10),
          _SupportedTextLines(
            lines: [scenario.ruleLine],
            language: selectedLanguage,
            showNative: showNative,
            vocabularyEntries: zeroOneDivisionVocabularyEntries,
            enableLearningSupport: true,
          ),
        ],
      ),
    );
  }
}

class _EqualShareInteractiveLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;
  final String nativeText;
  final String title;
  final List<SupportLine> problemLines;
  final SupportLine instructionLine;
  final List<SupportLine> resultLines;
  final SupportLine equationReading;
  final List<EquationSupport> equationSupports;
  final List<VocabularyEntry> vocabularyEntries;
  final List<int> storyOrder;
  final String successMessage;
  final String retryMessage;
  final String storyMessage;
  final String storyCompleteMessage;

  const _EqualShareInteractiveLearn({
    required this.selectedLanguage,
    required this.nativeText,
    this.title = '同じ数ずつ分けてみよう',
    this.problemLines = equalShareProblemLines,
    this.instructionLine = equalShareInstruction,
    List<SupportLine> resultLines = equalShareResultLines,
    SupportLine equationReading = equalShareEquationReading,
    List<EquationSupport> equationSupports = equalShareEquationSupports,
    List<VocabularyEntry> vocabularyEntries = equalShareVocabularyEntries,
    this.storyOrder = const [0, 1, 2, 0, 1, 2],
    this.successMessage = '同じ数ずつ分けられたね！',
    this.retryMessage = '同じ数になっているかな？ お皿ごとの数を見てみよう。',
    String storyMessage = '1こずつ順番に置いていきます。',
    String storyCompleteMessage = 'どのお皿も2こずつになりました。',
  }) : resultLines = resultLines,
       equationReading = equationReading,
       equationSupports = equationSupports,
       vocabularyEntries = vocabularyEntries,
       storyMessage = storyMessage,
       storyCompleteMessage = storyCompleteMessage;

  @override
  State<_EqualShareInteractiveLearn> createState() =>
      _EqualShareInteractiveLearnState();
}

class _EqualShareInteractiveLearnState
    extends State<_EqualShareInteractiveLearn> {
  static const int _berryCount = 6;
  static const int _plateCount = 3;
  final List<int?> _berryPlates = List<int?>.filled(_berryCount, null);
  late String _message;
  bool _isCorrect = false;
  bool _showProblemNative = false;
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  @override
  void initState() {
    super.initState();
    _message = widget.instructionLine.japanese;
  }

  void _moveBerry(int berryIndex, int? plateIndex) {
    setState(() {
      _berryPlates[berryIndex] = plateIndex;
      _isCorrect = false;
      _message = widget.instructionLine.japanese;
    });

    if (_berryPlates.every((plate) => plate != null)) {
      _checkAnswer(auto: true);
    }
  }

  void _checkAnswer({bool auto = false}) {
    final counts = _plateCounts;
    final complete = _berryPlates.every((plate) => plate != null);
    final correct = complete && counts.every((count) => count == 2);

    setState(() {
      _isCorrect = correct;
      if (correct) {
        _message = widget.successMessage;
      } else if (!complete && !auto) {
        _message = 'まだ入っていないいちごがあります。';
      } else {
        _message = widget.retryMessage;
      }
    });
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < _berryPlates.length; i++) {
        _berryPlates[i] = null;
      }
      _isCorrect = false;
      _message = widget.instructionLine.japanese;
    });
  }

  List<int> get _plateCounts {
    return [
      for (var plate = 0; plate < _plateCount; plate++)
        _berryPlates.where((value) => value == plate).length,
    ];
  }

  List<List<int>> get _plateBerryIds {
    return [
      for (var plate = 0; plate < _plateCount; plate++)
        [
          for (var i = 0; i < _berryPlates.length; i++)
            if (_berryPlates[i] == plate) i,
        ],
    ];
  }

  List<int> get _sourceBerryIds {
    return [
      for (var i = 0; i < _berryPlates.length; i++)
        if (_berryPlates[i] == null) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LearnNativeScope(
      showNative: _showProblemNative,
      language: widget.selectedLanguage,
      toggleNative: () {
        setState(() {
          _showProblemNative = !_showProblemNative;
          _showInstructionNative = _showProblemNative;
          _showResultNative = _showProblemNative;
        });
      },
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LearnHeaderIcon(icon: Icons.touch_app_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: RubyText(
                            text: widget.title,
                            vocabularyEntries: widget.vocabularyEntries,
                            language: widget.selectedLanguage,
                            learningSupportMode: LearningSupportMode.rubyOnly,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _IconSupportActions(
                          language: widget.selectedLanguage,
                          showNative: _showProblemNative,
                          translateLabel: _showProblemNative
                              ? '日本語で見る'
                              : '${widget.selectedLanguage.label}で見る',
                          audioLabel: '問題文の音声',
                          onToggleNative: () {
                            setState(() {
                              _showProblemNative = !_showProblemNative;
                            });
                          },
                          onAudio: () => _showAudioPlaceholder(
                            context,
                            '問題文',
                            widget.problemLines
                                .map((line) => line.japanese)
                                .join(' '),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _SupportedTextLines(
                      lines: widget.problemLines,
                      language: widget.selectedLanguage,
                      showNative: _showProblemNative,
                      vocabularyEntries: widget.vocabularyEntries,
                      fontWeight: FontWeight.w600,
                      enableLearningSupport: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        _EqualShareDragBoard(
            sourceBerryIds: _sourceBerryIds,
            plateBerryIds: _plateBerryIds,
            plateCounts: _plateCounts,
            isCorrect: _isCorrect,
            message: _message,
            onMoveBerry: _moveBerry,
            onReset: _reset,
            selectedLanguage: widget.selectedLanguage,
            showInstructionNative: _showInstructionNative,
            instructionLine: widget.instructionLine,
            successLine: widget.resultLines.first,
            vocabularyEntries: widget.vocabularyEntries,
            learningSupportMode: LearningSupportMode.rubyAndDictionary,
            onToggleInstructionNative: () {
              setState(() {
                _showInstructionNative = !_showInstructionNative;
              });
            },
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isCorrect
                ? _DivisionResultCard(
                    key: const ValueKey('correct-result'),
                    selectedLanguage: widget.selectedLanguage,
                    showNative: _showResultNative,
                    resultLines: widget.resultLines,
                    equationReading: widget.equationReading,
                    equationSupports: widget.equationSupports,
                    vocabularyEntries: widget.vocabularyEntries,
                    onToggleNative: () {
                      setState(() {
                        _showResultNative = !_showResultNative;
                      });
                    },
                    onAudio: () => _showAudioPlaceholder(
                      context,
                      '正解後の説明',
                      widget.resultLines.map((line) => line.japanese).join(' '),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty-result')),
          ),
        ],
      ),
      ),
    );
  }

  void _showAudioPlaceholder(BuildContext context, String label, String text) {
    LearningAudio.speakJapanese(context, label: label, text: text);
  }
}

class _EqualShareDragBoard extends StatelessWidget {
  final List<int> sourceBerryIds;
  final List<List<int>> plateBerryIds;
  final List<int> plateCounts;
  final bool isCorrect;
  final String message;
  final void Function(int berryIndex, int? plateIndex) onMoveBerry;
  final VoidCallback onReset;
  final AppLanguage selectedLanguage;
  final bool showInstructionNative;
  final SupportLine instructionLine;
  final SupportLine? successLine;
  final List<VocabularyEntry> vocabularyEntries;
  final LearningSupportMode? learningSupportMode;
  final VoidCallback onToggleInstructionNative;

  const _EqualShareDragBoard({
    required this.sourceBerryIds,
    required this.plateBerryIds,
    required this.plateCounts,
    required this.isCorrect,
    required this.message,
    required this.onMoveBerry,
    required this.onReset,
    required this.selectedLanguage,
    required this.showInstructionNative,
    this.instructionLine = equalShareInstruction,
    this.successLine,
    this.vocabularyEntries = const [],
    this.learningSupportMode,
    required this.onToggleInstructionNative,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final source = _BerrySourceTray(
          berryIds: sourceBerryIds,
          onAccept: (id) => onMoveBerry(id, null),
        );
        final plates = _PlateTargets(
          plateBerryIds: plateBerryIds,
          plateCounts: plateCounts,
          isCorrect: isCorrect,
          onMoveBerry: onMoveBerry,
          language: selectedLanguage,
          showNative: showInstructionNative,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InstructionStrip(
              message: message,
              isSuccess: isCorrect,
              language: selectedLanguage,
              showNative: showInstructionNative,
              instructionLine: instructionLine,
              successLine: successLine,
              vocabularyEntries: vocabularyEntries,
              learningSupportMode: learningSupportMode,
              onToggleNative: onToggleInstructionNative,
            ),
            const SizedBox(height: 14),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 260, child: source),
                  const SizedBox(width: 16),
                  Expanded(child: plates),
                ],
              )
            else
              Column(children: [source, const SizedBox(height: 14), plates]),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: _LearnIconButton(
                semanticLabel: 'もどす',
                icon: Icons.refresh_rounded,
                onPressed: onReset,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LearnIconButton extends StatelessWidget {
  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  const _LearnIconButton({
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 52,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(52, 52),
            fixedSize: const Size(52, 52),
            tapTargetSize: MaterialTapTargetSize.padded,
            side: const BorderSide(color: Color(0xFF9CA3AF), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Center(
            child: Icon(icon, size: 22, color: const Color(0xFF0082FF)),
          ),
        ),
      ),
    );
  }
}

class _BerrySourceTray extends StatelessWidget {
  final List<int> berryIds;
  final ValueChanged<int> onAccept;

  const _BerrySourceTray({required this.berryIds, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 224,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(text: 'いちご 6こ'),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final id in berryIds) _DraggableBerry(id: id),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlateTargets extends StatelessWidget {
  final List<List<int>> plateBerryIds;
  final List<int> plateCounts;
  final bool isCorrect;
  final void Function(int berryIndex, int? plateIndex) onMoveBerry;
  final AppLanguage language;
  final bool showNative;

  const _PlateTargets({
    required this.plateBerryIds,
    required this.plateCounts,
    required this.isCorrect,
    required this.onMoveBerry,
    this.language = AppLanguage.japanese,
    this.showNative = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final children = [
          for (var i = 0; i < plateBerryIds.length; i++)
            _PlateDropTarget(
              index: i,
              berryIds: plateBerryIds[i],
              count: plateCounts[i],
              isBalanced: plateCounts[i] == 2,
              showBalanced: isCorrect,
              onMoveBerry: onMoveBerry,
              language: language,
              showNative: showNative,
            ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _PlateDropTarget extends StatelessWidget {
  final int index;
  final List<int> berryIds;
  final int count;
  final bool isBalanced;
  final bool showBalanced;
  final void Function(int berryIndex, int? plateIndex) onMoveBerry;
  final AppLanguage language;
  final bool showNative;

  const _PlateDropTarget({
    required this.index,
    required this.berryIds,
    required this.count,
    required this.isBalanced,
    required this.showBalanced,
    required this.onMoveBerry,
    required this.language,
    required this.showNative,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) => onMoveBerry(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 224,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: showBalanced && isBalanced
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFD1D5DB),
              width: showBalanced && isBalanced ? 2 : 1.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                top: 34,
                child: CustomPaint(painter: _PlatePainter(active: active)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PersonPlateLabel(
                    index: index,
                    language: language,
                    showNative: showNative,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 76,
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final id in berryIds) _DraggableBerry(id: id),
                          if (berryIds.isEmpty)
                            const Text(
                              ' ',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(child: _CountBadge(count: count)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableBerry extends StatelessWidget {
  final int id;

  const _DraggableBerry({required this.id});

  @override
  Widget build(BuildContext context) {
    return Draggable<int>(
      data: id,
      feedback: const Material(
        color: Colors.transparent,
        child: _CounterDot(size: 42),
      ),
      childWhenDragging: const Opacity(
        opacity: 0.25,
        child: _CounterDot(size: 42),
      ),
      child: const _CounterDot(size: 42),
    );
  }
}

class _SupportedTextLines extends StatelessWidget {
  final List<SupportLine> lines;
  final AppLanguage language;
  final bool showNative;
  final List<VocabularyEntry> vocabularyEntries;
  final FontWeight fontWeight;
  final bool enableLearningSupport;
  final bool learningSupportRubyOnly;
  final LearningSupportMode? learningSupportMode;

  const _SupportedTextLines({
    required this.lines,
    required this.language,
    required this.showNative,
    this.vocabularyEntries = const [],
    this.fontWeight = FontWeight.w800,
    this.enableLearningSupport = false,
    bool learningSupportRubyOnly = false,
    this.learningSupportMode,
  }) : learningSupportRubyOnly = learningSupportRubyOnly;

  @override
  Widget build(BuildContext context) {
    final nativeScope = LearnNativeScope.maybeOf(context);
    final effectiveLanguage = LessonLanguageScope.of(
      context,
      nativeScope?.language ?? language,
    );
    final effectiveShowNative = nativeScope?.showNative ?? showNative;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          RubyText(
            text: line.rubyText,
            vocabularyEntries: vocabularyEntries,
            language: effectiveLanguage,
            enableLearningSupport: enableLearningSupport,
            learningSupportRubyOnly: learningSupportRubyOnly,
            learningSupportMode: learningSupportMode,
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 17,
              height: 1.35,
              fontWeight: fontWeight,
            ),
          ),
          if (effectiveShowNative &&
              effectiveLanguage != AppLanguage.japanese &&
              line.nativeFor(effectiveLanguage).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              line.nativeFor(effectiveLanguage),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class _IconSupportActions extends StatelessWidget {
  final AppLanguage language;
  final bool showNative;
  final String translateLabel;
  final String audioLabel;
  final VoidCallback onToggleNative;
  final VoidCallback onAudio;

  const _IconSupportActions({
    required this.language,
    required this.showNative,
    required this.translateLabel,
    required this.audioLabel,
    required this.onToggleNative,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    final nativeScope = LearnNativeScope.maybeOf(context);
    final effectiveLanguage = nativeScope?.language ?? language;
    final effectiveShowNative = nativeScope?.showNative ?? showNative;
    final onToggle = nativeScope?.toggleNative ?? onToggleNative;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (effectiveLanguage != AppLanguage.japanese) ...[
          _SupportIconButton(
            icon: Icons.translate_rounded,
            label: effectiveShowNative
                ? '日本語で見る'
                : '${effectiveLanguage.label}で見る',
            selected: effectiveShowNative,
            onPressed: onToggle,
          ),
          const SizedBox(width: 6),
        ],
        _SupportIconButton(
          icon: Icons.volume_up_rounded,
          label: audioLabel,
          onPressed: onAudio,
        ),
      ],
    );
  }
}

class _SupportIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _SupportIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? const Color(0xFFEFF6FF) : Colors.white;
    final foreground = selected
        ? const Color(0xFF2563EB)
        : const Color(0xFF374151);
    return IconButton(
      onPressed: onPressed,
      isSelected: selected,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

class _AudioIconButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AudioIconButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.volume_up_rounded),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        tooltip: label,
      ),
    );
  }
}

class _PersonPlateLabel extends StatelessWidget {
  final int index;
  final AppLanguage language;
  final bool showNative;

  const _PersonPlateLabel({
    required this.index,
    required this.language,
    required this.showNative,
  });

  @override
  Widget build(BuildContext context) {
    final native = equalSharePersonLabel(index, language);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 22),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(text: '${index + 1}人目'),
              if (showNative &&
                  language != AppLanguage.japanese &&
                  native.isNotEmpty)
                Text(
                  native,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionStrip extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final AppLanguage language;
  final bool showNative;
  final SupportLine instructionLine;
  final SupportLine? successLine;
  final VoidCallback onToggleNative;
  final List<VocabularyEntry> vocabularyEntries;
  final LearningSupportMode? learningSupportMode;

  const _InstructionStrip({
    required this.message,
    required this.isSuccess,
    required this.language,
    required this.showNative,
    this.instructionLine = equalShareInstruction,
    this.successLine,
    required this.onToggleNative,
    this.vocabularyEntries = const [],
    this.learningSupportMode,
  });

  @override
  Widget build(BuildContext context) {
    final line = isSuccess
        ? successLine ?? equalShareResultLines.first
        : message == instructionLine.japanese
        ? instructionLine
        : SupportLine(japanese: message);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RubyText(
                  text: line.japanese,
                  language: language,
                  vocabularyEntries: mergeLearningVocabulary(vocabularyEntries),
                  learningSupportMode: learningSupportMode ??
                      (isSuccess
                          ? LearningSupportMode.rubyAndDictionary
                          : LearningSupportMode.rubyOnly),
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF166534)
                        : message == instructionLine.japanese
                        ? const Color(0xFF374151)
                        : const Color(0xFF1E3A8A),
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _IconSupportActions(
                language: language,
                showNative: showNative,
                translateLabel: showNative ? '日本語で見る' : '${language.label}で見る',
                audioLabel: '操作案内の音声',
                onToggleNative: onToggleNative,
                onAudio: () {
                  LearningAudio.play(
                    context,
                    AudioCueFactory.instruction(
                      namespace: 'lesson.instruction_strip',
                      label: '操作案内',
                      text: line.japanese,
                    ),
                  );
                },
              ),
            ],
          ),
          if (showNative &&
              language != AppLanguage.japanese &&
              line.nativeFor(language).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              line.nativeFor(language),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DivisionResultCard extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final bool showNative;
  final List<SupportLine> resultLines;
  final SupportLine equationReading;
  final List<EquationSupport> equationSupports;
  final List<VocabularyEntry> vocabularyEntries;
  final VoidCallback onToggleNative;
  final VoidCallback onAudio;

  const _DivisionResultCard({
    super.key,
    required this.selectedLanguage,
    required this.showNative,
    this.resultLines = equalShareResultLines,
    this.equationReading = equalShareEquationReading,
    this.equationSupports = equalShareEquationSupports,
    this.vocabularyEntries = equalShareVocabularyEntries,
    required this.onToggleNative,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveVocabularyEntries = mergeLearningVocabulary(
      vocabularyEntries,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RubyText(
                  text: resultLines.first.rubyText,
                  vocabularyEntries: effectiveVocabularyEntries,
                  language: selectedLanguage,
                  enableLearningSupport: true,
                  learningSupportMode: LearningSupportMode.rubyAndDictionary,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _IconSupportActions(
                language: selectedLanguage,
                showNative: showNative,
                translateLabel: showNative
                    ? '日本語で見る'
                    : '${selectedLanguage.label}で見る',
                audioLabel: '正解説明の音声',
                onToggleNative: onToggleNative,
                onAudio: onAudio,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SupportedTextLines(
            lines: resultLines.skip(1).toList(),
            language: selectedLanguage,
            showNative: showNative,
            vocabularyEntries: effectiveVocabularyEntries,
            enableLearningSupport: true,
            learningSupportMode: LearningSupportMode.rubyAndDictionary,
          ),
          const SizedBox(height: 12),
          _EquationLine(language: selectedLanguage, supports: equationSupports),
          const SizedBox(height: 8),
          Row(
            children: [
              _AudioIconButton(
                label: '式の読み方の音声',
                onPressed: () {
                  LearningAudio.speakJapanese(
                    context,
                    label: '式の読み方',
                    text: equationReading.japanese,
                  );
                },
              ),
              Expanded(
                child: _SupportedTextLines(
                  lines: [equationReading],
                  language: selectedLanguage,
                  showNative: showNative,
                  vocabularyEntries: vocabularyEntries,
                  enableLearningSupport: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EquationLine extends StatelessWidget {
  final AppLanguage language;
  final List<EquationSupport> supports;

  const _EquationLine({required this.language, required this.supports});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EquationNumber(
            support: supports[0],
            color: const Color(0xFF2563EB),
            language: language,
          ),
          const _ResultEquationSymbol('÷'),
          _EquationNumber(
            support: supports[1],
            color: const Color(0xFFF97316),
            language: language,
          ),
          const _ResultEquationSymbol('='),
          _EquationNumber(
            support: supports[2],
            color: const Color(0xFF059669),
            language: language,
          ),
        ],
      ),
    );
  }
}

class _EquationNumber extends StatelessWidget {
  final EquationSupport support;
  final Color color;
  final AppLanguage language;

  const _EquationNumber({
    required this.support,
    required this.color,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showEquationMeaning(context),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 42,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, 4),
                  child: Text(
                    support.value,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: TextStyle(
                      color: color,
                      fontSize: 36,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              support.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEquationMeaning(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final native = support.nativeFor(language);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        support.label,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DictionaryAudioButton(
                      onPressed: () {
                        LearningAudio.speakJapanese(
                          context,
                          label: support.label,
                          text: support.label,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  support.meaning,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (language != AppLanguage.japanese && native.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    language.label,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    native,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DictionaryAudioButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DictionaryAudioButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: IconButton(
          tooltip: '音声',
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 20,
          color: const Color(0xFF374151),
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ),
    );
  }
}

class _ResultEquationSymbol extends StatelessWidget {
  final String value;

  const _ResultEquationSymbol(this.value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 42,
      child: Center(
        child: Text(
          value,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 112,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          text: TextSpan(
            style: const TextStyle(fontFamily: AppFonts.interface),
            children: [
              TextSpan(
                text: '$count',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TextSpan(
                text: 'こ',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EqualShareStoryMode extends StatelessWidget {
  final int step;
  final List<int> placements;
  final String storyMessage;
  final String storyCompleteMessage;
  final List<SupportLine> resultLines;
  final SupportLine equationReading;
  final List<EquationSupport> equationSupports;
  final List<VocabularyEntry> vocabularyEntries;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _EqualShareStoryMode({
    required this.step,
    required this.placements,
    String storyMessage = '1こずつ順番に置いていきます。',
    String storyCompleteMessage = 'どのお皿も2こずつになりました。',
    List<SupportLine> resultLines = equalShareResultLines,
    SupportLine equationReading = equalShareEquationReading,
    List<EquationSupport> equationSupports = equalShareEquationSupports,
    List<VocabularyEntry> vocabularyEntries = equalShareVocabularyEntries,
    required this.onNext,
    required this.onBack,
  }) : storyMessage = storyMessage,
       storyCompleteMessage = storyCompleteMessage,
       resultLines = resultLines,
       equationReading = equationReading,
       equationSupports = equationSupports,
       vocabularyEntries = vocabularyEntries;

  @override
  Widget build(BuildContext context) {
    final plateBerryIds = [
      for (var plate = 0; plate < 3; plate++)
        [
          for (var i = 0; i < placements.length; i++)
            if (placements[i] == plate) i,
        ],
    ];
    final sourceIds = [
      for (var i = 0; i < placements.length; i++)
        if (placements[i] == -1) i,
    ];
    final complete = step >= 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InstructionStrip(
          message: complete ? storyCompleteMessage : storyMessage,
          isSuccess: complete,
          language: AppLanguage.japanese,
          showNative: false,
          vocabularyEntries: vocabularyEntries,
          learningSupportMode: LearningSupportMode.rubyAndDictionary,
          onToggleNative: () {},
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final source = _StaticBerryTray(berryIds: sourceIds);
            final plates = _StaticPlateRow(plateBerryIds: plateBerryIds);
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 260, child: source),
                  const SizedBox(width: 16),
                  Expanded(child: plates),
                ],
              );
            }
            return Column(
              children: [source, const SizedBox(height: 14), plates],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: step == 0 ? null : onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(104, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('もどる'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: step >= 6 ? null : onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(step >= 6 ? 'できあがり' : 'つぎ'),
              ),
            ),
          ],
        ),
        if (complete) ...[
          const SizedBox(height: 14),
          _DivisionResultCard(
            selectedLanguage: AppLanguage.japanese,
            showNative: false,
            resultLines: resultLines,
            equationReading: equationReading,
            equationSupports: equationSupports,
            vocabularyEntries: vocabularyEntries,
            onToggleNative: () {},
            onAudio: () {},
          ),
        ],
      ],
    );
  }
}

class _StaticBerryTray extends StatelessWidget {
  final List<int> berryIds;

  const _StaticBerryTray({required this.berryIds});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'いちご 6こ'),
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final _ in berryIds) const _CounterDot(size: 42),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticPlateRow extends StatelessWidget {
  final List<List<int>> plateBerryIds;

  const _StaticPlateRow({required this.plateBerryIds});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final cards = [
          for (var i = 0; i < plateBerryIds.length; i++)
            _StaticPlateCard(index: i, berryIds: plateBerryIds[i]),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _StaticPlateCard extends StatelessWidget {
  final int index;
  final List<int> berryIds;

  const _StaticPlateCard({required this.index, required this.berryIds});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            top: 34,
            child: CustomPaint(painter: _PlatePainter(active: false)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PersonPlateLabel(
                index: index,
                language: AppLanguage.japanese,
                showNative: false,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 76,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final _ in berryIds) const _CounterDot(size: 42),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(child: _CountBadge(count: berryIds.length)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EqualShareWordsCard extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final List<LessonVocabulary> vocabularyItems;
  final double? vocabularyCardHeight;

  const _EqualShareWordsCard({
    required this.selectedLanguage,
    this.vocabularyItems = equalShareLessonVocabulary,
    this.vocabularyCardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              _LearnHeaderIcon(icon: Icons.menu_book_rounded),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'このレッスンで使うことば',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'このあと使うことばの意味を、絵と母語で確認しよう。',
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in vocabularyItems)
                    SizedBox(
                      width: cardWidth,
                      height: vocabularyCardHeight,
                      child: _LessonVocabularyCard(
                        vocabulary: item,
                        selectedLanguage: selectedLanguage,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LessonVocabularyCard extends StatelessWidget {
  final LessonVocabulary vocabulary;
  final AppLanguage selectedLanguage;

  const _LessonVocabularyCard({
    required this.vocabulary,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final translation = vocabulary.translationFor(selectedLanguage);
    final showNative =
        selectedLanguage != AppLanguage.japanese && translation.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            vocabulary.word,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _VocabularyAudioButton(
                          word: vocabulary.word,
                          reading: vocabulary.reading,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vocabulary.reading,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _VocabularyVisual(visual: vocabulary.visual),
            ],
          ),
          const SizedBox(height: 14),
          if (showNative) ...[
            Text(
              selectedLanguage.label,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              translation,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            vocabulary.explanation,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyAudioButton extends StatelessWidget {
  final String word;
  final String reading;

  const _VocabularyAudioButton({required this.word, required this.reading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: IconButton(
          tooltip: '$word の音声',
          onPressed: () {
            final normalizedReading = reading.replaceAll(' ', '');
            LearningAudio.speakJapanese(
              context,
              label: word,
              text: normalizedReading.isEmpty ? word : normalizedReading,
            );
          },
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 20,
          color: const Color(0xFF374151),
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ),
    );
  }
}

class _VocabularyVisual extends StatelessWidget {
  final LessonVocabularyVisual visual;

  const _VocabularyVisual({required this.visual});

  @override
  Widget build(BuildContext context) {
    if (visual == LessonVocabularyVisual.none) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 116,
      height: 76,
      child: switch (visual) {
        LessonVocabularyVisual.equalGroups => const _EqualGroupsVisual(),
        LessonVocabularyVisual.splitToPlates => const _SplitToPlatesVisual(),
        LessonVocabularyVisual.onePersonShare => const _OnePersonShareVisual(),
        LessonVocabularyVisual.countQuestion => const _CountQuestionVisual(),
        LessonVocabularyVisual.divideByOne => const _DivideByOneVisual(),
        LessonVocabularyVisual.zeroItems => const _ZeroItemsVisual(),
        LessonVocabularyVisual.divideByZero => const _DivideByZeroVisual(),
        LessonVocabularyVisual.remainder => const _RemainderWordVisual(),
        LessonVocabularyVisual.divisor => const _DivisorWordVisual(),
        LessonVocabularyVisual.dividend => const _DividendWordVisual(),
        LessonVocabularyVisual.roundUpRemainder =>
          const _RoundUpRemainderVisual(),
        LessonVocabularyVisual.none => const SizedBox.shrink(),
      },
    );
  }
}

class _RemainderWordVisual extends StatelessWidget {
  const _RemainderWordVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _MiniPlate(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterDot(size: 11),
              SizedBox(width: 2),
              _CounterDot(size: 11),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(
          '+1',
          style: TextStyle(
            color: Color(0xFFB45309),
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DivisorWordVisual extends StatelessWidget {
  const _DivisorWordVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          '7 ÷ ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(
          '3',
          style: TextStyle(
            color: Color(0xFFF97316),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DividendWordVisual extends StatelessWidget {
  const _DividendWordVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          '7',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          ' ÷ 3',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _RoundUpRemainderVisual extends StatelessWidget {
  const _RoundUpRemainderVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _MiniPlate(
          child: Text('4', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        SizedBox(width: 4),
        _MiniPlate(
          child: Text('4', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        SizedBox(width: 7),
        Icon(Icons.add_rounded, color: Color(0xFFB45309), size: 20),
        _MiniPlate(
          child: Text('1', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _DivideByOneVisual extends StatelessWidget {
  const _DivideByOneVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.person_rounded, color: Color(0xFF4B5563), size: 20),
        SizedBox(width: 6),
        _MiniPlate(
          width: 62,
          height: 40,
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              _CounterDot(size: 11),
              _CounterDot(size: 11),
              _CounterDot(size: 11),
              _CounterDot(size: 11),
              _CounterDot(size: 11),
              _CounterDot(size: 11),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZeroItemsVisual extends StatelessWidget {
  const _ZeroItemsVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _MiniPlate(
          child: Text(
            '0',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _MiniPlate(
          child: Text(
            '0',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _MiniPlate(
          child: Text(
            '0',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DivideByZeroVisual extends StatelessWidget {
  const _DivideByZeroVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          width: 46,
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              _CounterDot(size: 12),
              _CounterDot(size: 12),
              _CounterDot(size: 12),
              _CounterDot(size: 12),
              _CounterDot(size: 12),
              _CounterDot(size: 12),
            ],
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.person_off_rounded, color: Color(0xFF6B7280), size: 28),
        SizedBox(width: 3),
        Text(
          '?',
          style: TextStyle(
            color: Color(0xFFB45309),
            fontSize: 26,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EqualGroupsVisual extends StatelessWidget {
  const _EqualGroupsVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 3; i++)
          _MiniPlate(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CounterDot(size: 13),
                SizedBox(width: 2),
                _CounterDot(size: 13),
              ],
            ),
          ),
      ],
    );
  }
}

class _SplitToPlatesVisual extends StatelessWidget {
  const _SplitToPlatesVisual();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 36,
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              _CounterDot(size: 14),
              _CounterDot(size: 14),
              _CounterDot(size: 14),
              _CounterDot(size: 14),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_rounded,
          color: Color(0xFF9CA3AF),
          size: 22,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [_MiniPlate(), SizedBox(height: 6), _MiniPlate()],
          ),
        ),
      ],
    );
  }
}

class _OnePersonShareVisual extends StatelessWidget {
  const _OnePersonShareVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.person_rounded, color: Color(0xFF4B5563), size: 22),
        SizedBox(height: 3),
        _MiniPlate(
          width: 58,
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterDot(size: 16),
              SizedBox(width: 4),
              _CounterDot(size: 16),
            ],
          ),
        ),
        SizedBox(height: 3),
        Text(
          '1人に2こ',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CountQuestionVisual extends StatelessWidget {
  const _CountQuestionVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniPersonWithPlate(),
            SizedBox(width: 4),
            _MiniPersonWithPlate(),
            SizedBox(width: 4),
            Text(
              '?',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '何人？',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MiniPersonWithPlate extends StatelessWidget {
  const _MiniPersonWithPlate();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.person_rounded, color: Color(0xFF6B7280), size: 14),
        SizedBox(height: 1),
        _MiniPlate(
          width: 30,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterDot(size: 9),
              SizedBox(width: 2),
              _CounterDot(size: 9),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniPlate extends StatelessWidget {
  final Widget? child;
  final double width;
  final double height;

  const _MiniPlate({this.child, this.width = 34, this.height = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: child,
    );
  }
}

class _LearnHeaderIcon extends StatelessWidget {
  final IconData icon;

  const _LearnHeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Icon(icon, color: const Color(0xFF2563EB), size: 28),
    );
  }
}

class _CounterDot extends StatelessWidget {
  final double size;

  const _CounterDot({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StrawberryPainter()),
    );
  }
}

class _StrawberryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: const [Color(0xFFFF7A7A), Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final borderPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;
    final leafPaint = Paint()..color = const Color(0xFF15803D);
    final seedPaint = Paint()..color = const Color(0xFFEFE7B0);

    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.96)
      ..cubicTo(
        size.width * 0.06,
        size.height * 0.66,
        size.width * 0.12,
        size.height * 0.23,
        size.width * 0.5,
        size.height * 0.2,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.23,
        size.width * 0.94,
        size.height * 0.66,
        size.width * 0.5,
        size.height * 0.96,
      )
      ..close();

    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, borderPaint);

    final leaf = Path()
      ..moveTo(size.width * 0.5, size.height * 0.24)
      ..lineTo(size.width * 0.28, size.height * 0.04)
      ..lineTo(size.width * 0.46, size.height * 0.14)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.54, size.height * 0.14)
      ..lineTo(size.width * 0.72, size.height * 0.04)
      ..close();
    canvas.drawPath(leaf, leafPaint);

    final seeds = const [
      Offset(0.39, 0.43),
      Offset(0.58, 0.45),
      Offset(0.32, 0.58),
      Offset(0.5, 0.62),
      Offset(0.68, 0.6),
      Offset(0.43, 0.76),
      Offset(0.58, 0.76),
    ];
    for (final seed in seeds) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * seed.dx, size.height * seed.dy),
          width: size.width * 0.024,
          height: size.width * 0.05,
        ),
        seedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlatePainter extends CustomPainter {
  final bool active;

  const _PlatePainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final outerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.82,
      height: size.height * 0.62,
    );
    final innerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.58,
      height: size.height * 0.36,
    );

    final outerPaint = Paint()
      ..color = active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = active ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(outerRect, outerPaint);
    canvas.drawOval(outerRect, borderPaint);
    canvas.drawOval(innerRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PlatePainter oldDelegate) {
    return oldDelegate.active != active;
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
  final ValueChanged<QuestionPromptMode> onTap;

  const _PromptModeCard({
    required this.mode,
    required this.selectedMode,
    required this.icon,
    required this.title,
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
                child: Text(
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
                  Color(0xFF2563EB),
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
  final bool useCompactLayout;
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _AnswerCard({
    required this.rubyText,
    required this.useCompactLayout,
    required this.vocabularyEntries,
    required this.language,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.trailingIcon,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = useCompactLayout;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 20,
            vertical: compact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: compact
                    ? _CompactChoiceText(
                        text: rubyText,
                        color: textColor,
                        vocabularyEntries: vocabularyEntries,
                        language: language,
                      )
                    : RubyText(
                        text: rubyText,
                        textAlign: TextAlign.center,
                        vocabularyEntries: vocabularyEntries,
                        language: language,
                        style: TextStyle(
                          fontSize: 29,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                        rubyStyle: TextStyle(
                          fontSize: 12,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: textColor.withValues(alpha: 0.72),
                        ),
                      ),
              ),
              if (trailingIcon != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(trailingIcon, color: trailingColor, size: 26),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _choiceTextLooksCompact(String value) {
  final plain = value.replaceAllMapped(
    RegExp(r'\{([^|{}]+)\|([^{}]+)\}'),
    (match) => match.group(1) ?? '',
  );
  if (RegExp(r'[+＋\-−×÷=＝]').hasMatch(plain)) {
    return true;
  }
  if (plain.length <= 6 && !RegExp(r'\s').hasMatch(plain)) {
    return true;
  }
  return plain.length <= 8 &&
      RegExp(
        r'^[0-9０-９一二三四五六七八九十+＋\-−×÷=＝、.．mcm本人こまい枚袋台組箱本つ個こ]+$',
      ).hasMatch(plain);
}

class _CompactChoiceText extends StatelessWidget {
  final String text;
  final Color color;
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;

  const _CompactChoiceText({
    required this.text,
    required this.color,
    required this.vocabularyEntries,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final plain = text.replaceAllMapped(
      RegExp(r'\{([^|{}]+)\|([^{}]+)\}'),
      (match) => match.group(1) ?? '',
    );
    final isExpression = RegExp(r'[+＋\-−×÷=＝]').hasMatch(plain);
    if (isExpression) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            plain,
            textAlign: TextAlign.center,
            strutStyle: const StrutStyle(
              fontSize: 38,
              height: 1,
              forceStrutHeight: true,
              fontFamily: AppFonts.interface,
            ),
            style: TextStyle(
              color: color,
              fontFamily: AppFonts.interface,
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    }

    if (text.contains('{')) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: RubyText(
            text: text,
            textAlign: TextAlign.center,
            vocabularyEntries: vocabularyEntries,
            language: language,
            style: TextStyle(
              color: color,
              fontSize: 36,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            rubyStyle: TextStyle(
              color: color.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    }

    final match = RegExp(r'^([0-9０-９]+)(.*)$').firstMatch(plain);
    final number = match?.group(1);
    final suffix = match == null ? plain : match.group(2) ?? '';

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RichText(
        textAlign: TextAlign.center,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        text: TextSpan(
          style: TextStyle(
            color: color,
            fontFamily: AppFonts.interface,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
          children: [
            if (number != null)
              TextSpan(
                text: number,
                style: const TextStyle(fontSize: 38, letterSpacing: 0),
              ),
            TextSpan(
              text: suffix,
              style: const TextStyle(fontSize: 38, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageAnswerCard extends StatelessWidget {
  final String labelRuby;
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;
  final String imageUrl;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _ImageAnswerCard({
    required this.labelRuby,
    required this.vocabularyEntries,
    required this.language,
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
                      vocabularyEntries: vocabularyEntries,
                      language: language,
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

class _DiagramAnswerCard extends StatelessWidget {
  final Map<String, String> diagram;
  final String itemKind;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _DiagramAnswerCard({
    required this.diagram,
    required this.itemKind,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.trailingIcon,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final groups = int.tryParse(diagram['groups'] ?? '') ?? 0;
    final each = int.tryParse(diagram['each'] ?? '') ?? 0;
    final labelSuffix = diagram['labelSuffix'] ?? '人目';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: _ChoiceEqualShareDiagram(
                  groups: groups,
                  each: each,
                  labelSuffix: labelSuffix,
                  itemKind: itemKind,
                ),
              ),
              if (trailingIcon != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(trailingIcon, color: trailingColor, size: 26),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceEqualShareDiagram extends StatelessWidget {
  final int groups;
  final int each;
  final String labelSuffix;
  final String itemKind;

  const _ChoiceEqualShareDiagram({
    required this.groups,
    required this.each,
    required this.labelSuffix,
    required this.itemKind,
  });

  @override
  Widget build(BuildContext context) {
    if (groups <= 0 || each <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = groups <= 3 ? groups : 3;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < groups; index++)
                SizedBox(
                  width: cardWidth.clamp(72, 120).toDouble(),
                  child: _MiniPersonShareBox(
                    index: index,
                    count: each,
                    labelSuffix: labelSuffix,
                    itemKind: itemKind,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniPersonShareBox extends StatelessWidget {
  final int index;
  final int count;
  final String labelSuffix;
  final String itemKind;

  const _MiniPersonShareBox({
    required this.index,
    required this.count,
    required this.labelSuffix,
    required this.itemKind,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}$labelSuffix',
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: itemKind == 'candy' ? 1 : 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < count; i++) _MiniDiagramItem(kind: itemKind),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniDiagramItem extends StatelessWidget {
  final String kind;

  const _MiniDiagramItem({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isCandy = kind == 'candy';
    return SizedBox(
      width: isCandy ? 20 : 14,
      height: isCandy ? 18 : 14,
      child: CustomPaint(
        painter: switch (kind) {
          'candy' => const _MiniCandyPainter(),
          'apple' => const _MiniApplePainter(),
          'strawberry' => const _MiniStrawberryPainter(),
          'cookie' => const _MiniCookiePainter(),
          'card' => const _MiniCardItemPainter(),
          'marble' => const _MiniMarblePainter(),
          'pencil' => const _MiniPencilPainter(),
          _ => const _MiniStickerPainter(),
        },
      ),
    );
  }
}

class _MiniCandyPainter extends CustomPainter {
  const _MiniCandyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.62,
        height: size.height * 0.52,
      ),
      Radius.circular(size.height * 0.2),
    );
    final left = Path()
      ..moveTo(size.width * 0.28, center.dy)
      ..lineTo(size.width * 0.04, size.height * 0.28)
      ..lineTo(size.width * 0.04, size.height * 0.72)
      ..close();
    final right = Path()
      ..moveTo(size.width * 0.72, center.dy)
      ..lineTo(size.width * 0.96, size.height * 0.28)
      ..lineTo(size.width * 0.96, size.height * 0.72)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawPath(right, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFFFCA5A5), Color(0xFFEF4444)],
        ).createShader(bodyRect.outerRect),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center.translate(-size.width * 0.12, -size.height * 0.1),
      size.width * 0.08,
      Paint()..color = const Color(0x80FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniCandyPainter oldDelegate) => false;
}

class _MiniApplePainter extends CustomPainter {
  const _MiniApplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final radius = size.shortestSide * 0.36;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.12),
        width: radius * 1.55,
        height: radius * 0.5,
      ),
      Paint()
        ..color = const Color(0x220F172A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.26)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.22,
        size.width * 0.34,
        size.height * 0.22,
        size.width * 0.27,
        size.height * 0.29,
      )
      ..cubicTo(
        size.width * 0.1,
        size.height * 0.46,
        size.width * 0.18,
        size.height * 0.84,
        size.width * 0.43,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.89,
        size.width * 0.52,
        size.height * 0.89,
        size.width * 0.57,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.84,
        size.width * 0.9,
        size.height * 0.46,
        size.width * 0.73,
        size.height * 0.29,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.22,
        size.width * 0.58,
        size.height * 0.22,
        size.width * 0.5,
        size.height * 0.26,
      )
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: const [
            Color(0xFFFF8A65),
            Color(0xFFE53935),
            Color(0xFFB91C1C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.27),
        width: radius * 0.62,
        height: radius * 0.28,
      ),
      Paint()..color = const Color(0x220F172A),
    );
    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.28),
      Offset(size.width * 0.58, size.height * 0.1),
      Paint()
        ..color = const Color(0xFF7C2D12)
        ..strokeWidth = size.shortestSide * 0.07
        ..strokeCap = StrokeCap.round,
    );
    final leaf = Path()
      ..moveTo(size.width * 0.58, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.06,
        size.width * 0.72,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.63,
        size.height * 0.25,
        size.width * 0.58,
        size.height * 0.18,
      );
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.28),
      radius * 0.18,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniApplePainter oldDelegate) => false;
}

class _MiniStrawberryPainter extends CustomPainter {
  const _MiniStrawberryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.97)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.74,
        size.width * 0.12,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.2,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.3,
        size.width * 0.85,
        size.height * 0.74,
        size.width * 0.5,
        size.height * 0.97,
      )
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: const [
            Color(0xFFFF8A8A),
            Color(0xFFEF4444),
            Color(0xFFB91C1C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    for (final p in const [
      Offset(0.42, 0.46),
      Offset(0.58, 0.47),
      Offset(0.34, 0.6),
      Offset(0.5, 0.63),
      Offset(0.66, 0.6),
      Offset(0.43, 0.76),
      Offset(0.57, 0.77),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * p.dx, size.height * p.dy),
          width: size.shortestSide * 0.018,
          height: size.shortestSide * 0.038,
        ),
        Paint()..color = const Color(0xFFEFE7B0),
      );
    }
    final leafPaint = Paint()..color = const Color(0xFF15803D);
    for (final dx in const [-0.2, 0.0, 0.2]) {
      final path = Path()
        ..moveTo(size.width * 0.5, size.height * 0.2)
        ..lineTo(size.width * (0.5 + dx), size.height * 0.04)
        ..lineTo(size.width * (0.43 + dx * 0.3), size.height * 0.3)
        ..close();
      canvas.drawPath(path, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniStrawberryPainter oldDelegate) => false;
}

class _MiniCookiePainter extends CustomPainter {
  const _MiniCookiePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: const [
            Color(0xFFFDE68A),
            Color(0xFFF59E0B),
            Color(0xFFB45309),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final chipPaint = Paint()..color = const Color(0xFF7C2D12);
    for (final p in const [
      Offset(0.36, 0.36),
      Offset(0.6, 0.35),
      Offset(0.67, 0.57),
      Offset(0.44, 0.64),
    ]) {
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        radius * 0.13,
        chipPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCookiePainter oldDelegate) => false;
}

class _MiniPencilPainter extends CustomPainter {
  const _MiniPencilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-size.width * 0.5, -size.height * 0.5);

    final y = size.height * 0.52;
    final bodyLeft = size.width * 0.14;
    final bodyRight = size.width * 0.76;
    final bodyHeight = size.height * 0.34;
    final bodyRect = Rect.fromLTWH(
      bodyLeft,
      y - bodyHeight / 2,
      bodyRight - bodyLeft,
      bodyHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.02,
          y - bodyHeight * 0.55,
          size.width * 0.13,
          bodyHeight * 1.1,
        ),
        Radius.circular(bodyHeight * 0.18),
      ),
      Paint()..color = const Color(0xFFFCA5A5),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.14,
        y - bodyHeight * 0.55,
        size.width * 0.035,
        bodyHeight * 1.1,
      ),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.drawRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFF1A8),
            Color(0xFFFBBF24),
            Color(0xFFD97706),
          ],
        ).createShader(bodyRect),
    );
    canvas.drawLine(
      Offset(bodyLeft + 1, y - bodyHeight * 0.18),
      Offset(bodyRight - 1, y - bodyHeight * 0.18),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
    final wood = Path()
      ..moveTo(bodyRight, y - bodyHeight / 2)
      ..lineTo(size.width * 0.96, y)
      ..lineTo(bodyRight, y + bodyHeight / 2)
      ..close();
    canvas.drawPath(wood, Paint()..color = const Color(0xFFF6D6A7));
    final lead = Path()
      ..moveTo(size.width * 0.96, y)
      ..lineTo(size.width * 0.84, y - bodyHeight * 0.32)
      ..lineTo(size.width * 0.84, y + bodyHeight * 0.32)
      ..close();
    canvas.drawPath(lead, Paint()..color = const Color(0xFF111827));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniPencilPainter oldDelegate) => false;
}

class _MiniCardItemPainter extends CustomPainter {
  const _MiniCardItemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.14,
        size.width * 0.56,
        size.height * 0.72,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniCardItemPainter oldDelegate) => false;
}

class _MiniMarblePainter extends CustomPainter {
  const _MiniMarblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: const [
            Color(0xFFE0F7FA),
            Color(0xFF22D3EE),
            Color(0xFF0891B2),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.32),
      radius * 0.18,
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMarblePainter oldDelegate) => false;
}

class _MiniStickerPainter extends CustomPainter {
  const _MiniStickerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    canvas.drawCircle(
      center.translate(0, 0.8),
      radius,
      Paint()
        ..color = const Color(0x1F0F172A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.24, -radius * 0.32),
        width: radius * 0.62,
        height: radius * 0.34,
      ),
      Paint()..color = const Color(0x99FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniStickerPainter oldDelegate) => false;
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
        textStyle: const TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
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
  final AppLanguage questionLanguage;
  final AppLanguage explanationLanguage;
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
    required this.questionLanguage,
    required this.explanationLanguage,
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
    final showCorrectAnswerCard =
        !(question.type == 'select_picture' &&
            question.choiceDiagramData.isNotEmpty);

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
                              if (showCorrectAnswerCard) ...[
                                _CorrectAnswerCard(
                                  text: correctAnswerText,
                                  vocabularyEntries: question.vocabularyEntries,
                                  language: questionLanguage,
                                ),
                                const SizedBox(height: 12),
                              ],
                              _SolutionExplanationCard(
                                question: question,
                                language: explanationLanguage,
                                japaneseExplanation: question
                                    .explanationRubyFor(AppLanguage.japanese),
                                nativeExplanation: question
                                    .explanationNative[explanationLanguage],
                                formulaText: formulaExplanation,
                                visualHint: visualHint,
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
                                fontFamily: AppFonts.interface,
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

class _CorrectAnswerCard extends StatelessWidget {
  final String text;
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;

  const _CorrectAnswerCard({
    required this.text,
    required this.vocabularyEntries,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '正しい答え',
            style: TextStyle(
              color: Color(0xFF16A34A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          RubyText(
            text: text,
            vocabularyEntries: vocabularyEntries,
            language: language,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 32,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionExplanationCard extends StatefulWidget {
  final Question question;
  final AppLanguage language;
  final String japaneseExplanation;
  final String? nativeExplanation;
  final String formulaText;
  final String visualHint;

  const _SolutionExplanationCard({
    required this.question,
    required this.language,
    required this.japaneseExplanation,
    required this.nativeExplanation,
    required this.formulaText,
    required this.visualHint,
  });

  @override
  State<_SolutionExplanationCard> createState() =>
      _SolutionExplanationCardState();
}

class _SolutionExplanationCardState extends State<_SolutionExplanationCard> {
  bool showNative = false;

  bool get hasNativeExplanation {
    return widget.language != AppLanguage.japanese &&
        widget.nativeExplanation != null &&
        widget.nativeExplanation!.trim().isNotEmpty;
  }

  String get visibleExplanation {
    if (showNative && hasNativeExplanation) {
      return widget.nativeExplanation!;
    }
    return widget.japaneseExplanation;
  }

  AppLanguage get visibleLanguage {
    return showNative && hasNativeExplanation
        ? widget.language
        : AppLanguage.japanese;
  }

  @override
  Widget build(BuildContext context) {
    final visualHint = widget.visualHint.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '解き方',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (hasNativeExplanation)
                _ExplanationLanguageToggle(
                  showNative: showNative,
                  language: widget.language,
                  onChanged: (value) {
                    setState(() {
                      showNative = value;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.question.hasVisual &&
              widget.question.diagramData['showInExplanation'] != 'false') ...[
            QuestionVisual(
              question: widget.question,
              compact: true,
              showSolution: true,
            ),
            const SizedBox(height: 14),
          ] else if (visualHint.isNotEmpty) ...[
            _VisualHintLine(text: visualHint),
            const SizedBox(height: 14),
          ],
          if (visibleExplanation.isNotEmpty) ...[
            RubyText(
              text: visibleExplanation,
              vocabularyEntries: widget.question.vocabularyEntries,
              language: visibleLanguage,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
          ],
          RubyText(
            text: _answerSummaryText(widget.question, visibleLanguage),
            vocabularyEntries: widget.question.vocabularyEntries,
            language: visibleLanguage,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _answerSummaryText(Question question, AppLanguage language) {
  final answer = question.resolvedCorrectAnswerTextRuby;
  if (language == AppLanguage.portuguese) {
    final translatedAnswer = _portugueseAnswerText(question, answer);
    return 'A resposta é $translatedAnswer.';
  }
  return '答えは $answer です。';
}

String _portugueseAnswerText(Question question, String answer) {
  final questionText = '${question.promptSchoolJa} ${question.promptEasyJa}';
  if ((question.itemEmoji == '🍎' || questionText.contains('りんご')) &&
      answer.endsWith('こ')) {
    return answer.replaceFirst('こ', ' maçãs');
  }
  if ((question.itemEmoji == '🍬' || questionText.contains('あめ')) &&
      answer.endsWith('こ')) {
    return answer.replaceFirst('こ', ' balas');
  }
  if ((question.itemEmoji == '🍪' || questionText.contains('クッキー')) &&
      answer.endsWith('こ')) {
    return answer.replaceFirst('こ', ' biscoitos');
  }
  if (answer.endsWith('人')) {
    final value = answer.substring(0, answer.length - 1);
    return '$value pessoas';
  }
  if (answer.endsWith('本')) {
    final value = answer.substring(0, answer.length - 1);
    return '$value lápis';
  }
  if (answer.endsWith('まい')) {
    final value = answer.substring(0, answer.length - 2);
    return '$value cartões';
  }
  return answer;
}

class _ExplanationLanguageToggle extends StatelessWidget {
  final bool showNative;
  final AppLanguage language;
  final ValueChanged<bool> onChanged;

  const _ExplanationLanguageToggle({
    required this.showNative,
    required this.language,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ExplanationLanguageOption(
            label: '日本語',
            selected: !showNative,
            onTap: () => onChanged(false),
          ),
          _ExplanationLanguageOption(
            label: language.label,
            selected: showNative,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ExplanationLanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExplanationLanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36, minWidth: 76),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _VisualHintLine extends StatelessWidget {
  final String text;

  const _VisualHintLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
