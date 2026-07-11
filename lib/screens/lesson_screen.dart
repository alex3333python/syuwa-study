import 'package:flutter/material.dart';

import '../data/equal_share_language_support.dart';
import '../models/answer_record.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
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
                          vocabularyEntries: question.vocabularyEntries,
                          language: widget.selectedLanguage,
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
            questionLanguage: widget.selectedLanguage,
            correctAnswerText: question.resolvedCorrectAnswerTextRuby,
            explanationText: question.explanationRubyFor(
              widget.selectedLanguage,
            ),
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
    final richLearnCard = _buildRichLearnCard(step, widget.selectedLanguage);
    final actionLabel = step.id == 'division-equal-share-words'
        ? 'もんだいをとく'
        : currentStepIndex == widget.lesson.steps.length - 1
        ? '完了'
        : '次へ';

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
                    if (richLearnCard != null) ...[
                      richLearnCard,
                      const SizedBox(height: 16),
                    ] else ...[
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
              vocabularyEntries: currentQuestion.vocabularyEntries,
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
              vocabularyEntries: currentQuestion.vocabularyEntries,
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
      return _DivisionLearnStoryboard(
        mode: _DivisionLearnMode.measure,
        selectedLanguage: selectedLanguage,
        nativeText: step.explanationFor(
          selectedLanguage,
          QuestionPromptMode.native,
        ),
      );
  }
  return null;
}

enum _DivisionLearnMode { equalShare, measure }

class _EqualShareInteractiveLearn extends StatefulWidget {
  final AppLanguage selectedLanguage;
  final String nativeText;

  const _EqualShareInteractiveLearn({
    required this.selectedLanguage,
    required this.nativeText,
  });

  @override
  State<_EqualShareInteractiveLearn> createState() =>
      _EqualShareInteractiveLearnState();
}

class _EqualShareInteractiveLearnState
    extends State<_EqualShareInteractiveLearn> {
  static const int _berryCount = 6;
  static const int _plateCount = 3;
  final List<int?> _berryPlates = List<int?>.filled(_berryCount, null);
  bool _showStory = false;
  int _storyStep = 0;
  String _message = equalShareInstruction.japanese;
  bool _isCorrect = false;
  bool _showProblemNative = false;
  bool _showInstructionNative = false;
  bool _showResultNative = false;

  void _moveBerry(int berryIndex, int? plateIndex) {
    setState(() {
      _berryPlates[berryIndex] = plateIndex;
      _isCorrect = false;
      _message = equalShareInstruction.japanese;
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
        _message = '同じ数ずつ分けられたね！';
      } else if (!complete && !auto) {
        _message = 'まだ入っていないいちごがあります。';
      } else {
        _message = '同じ数になっているかな？ お皿ごとの数を見てみよう。';
      }
    });
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < _berryPlates.length; i++) {
        _berryPlates[i] = null;
      }
      _isCorrect = false;
      _message = equalShareInstruction.japanese;
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

  List<int> _storyPlateForStep(int step) {
    final placements = <int>[];
    const order = [0, 1, 2, 0, 1, 2];
    for (var i = 0; i < _berryCount; i++) {
      placements.add(i < step ? order[i] : -1);
    }
    return placements;
  }

  @override
  Widget build(BuildContext context) {
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
              const _LearnHeaderIcon(icon: Icons.touch_app_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '同じ数ずつ分けてみよう',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _SupportedTextLines(
                      lines: equalShareProblemLines,
                      language: widget.selectedLanguage,
                      showNative: _showProblemNative,
                      vocabularyEntries: equalShareVocabularyEntries,
                    ),
                    const SizedBox(height: 8),
                    _LanguageSupportActions(
                      language: widget.selectedLanguage,
                      showNative: _showProblemNative,
                      onToggleNative: () {
                        setState(() {
                          _showProblemNative = !_showProblemNative;
                        });
                      },
                      onAudio: () => _showAudioPlaceholder(
                        context,
                        '問題文',
                        equalShareProblemLines
                            .map((line) => line.japanese)
                            .join(' '),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _LearnIconButton(
                semanticLabel: _showStory ? '操作する' : '見てみる',
                icon: _showStory
                    ? Icons.pan_tool_alt_rounded
                    : Icons.play_circle_outline_rounded,
                onPressed: () {
                  setState(() {
                    _showStory = !_showStory;
                    _storyStep = 0;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_showStory)
            _EqualShareStoryMode(
              step: _storyStep,
              placements: _storyPlateForStep(_storyStep),
              onNext: () {
                setState(() {
                  _storyStep = (_storyStep + 1).clamp(0, 6);
                });
              },
              onBack: () {
                setState(() {
                  _storyStep = (_storyStep - 1).clamp(0, 6);
                });
              },
            )
          else
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
                    onToggleNative: () {
                      setState(() {
                        _showResultNative = !_showResultNative;
                      });
                    },
                    onAudio: () => _showAudioPlaceholder(
                      context,
                      '正解後の説明',
                      equalShareResultLines
                          .map((line) => line.japanese)
                          .join(' '),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty-result')),
          ),
        ],
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
  final VoidCallback onPressed;

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
        width: 58,
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(58, 48),
            fixedSize: const Size(58, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
            side: const BorderSide(color: Color(0xFF9CA3AF), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Center(
            child: Icon(icon, size: 22, color: const Color(0xFF4F46E5)),
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
          constraints: const BoxConstraints(minHeight: 176),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final id in berryIds) _DraggableBerry(id: id)],
              ),
              if (berryIds.isEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  ' ',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
          constraints: const BoxConstraints(minHeight: 176),
          padding: const EdgeInsets.all(14),
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
                top: 30,
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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
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
                  const SizedBox(height: 10),
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

  const _SupportedTextLines({
    required this.lines,
    required this.language,
    required this.showNative,
    this.vocabularyEntries = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          RubyText(
            text: line.japanese,
            vocabularyEntries: vocabularyEntries,
            language: language,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (showNative &&
              language != AppLanguage.japanese &&
              line.nativeFor(language).isNotEmpty) ...[
            const SizedBox(height: 3),
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
          const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class _LanguageSupportActions extends StatelessWidget {
  final AppLanguage language;
  final bool showNative;
  final VoidCallback onToggleNative;
  final VoidCallback onAudio;

  const _LanguageSupportActions({
    required this.language,
    required this.showNative,
    required this.onToggleNative,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (language != AppLanguage.japanese)
          _InlineSupportButton(
            icon: Icons.translate_rounded,
            label: showNative ? '日本語' : language.label,
            onPressed: onToggleNative,
          ),
        _InlineSupportButton(
          icon: Icons.volume_up_rounded,
          label: '音声',
          onPressed: onAudio,
        ),
      ],
    );
  }
}

class _InlineSupportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _InlineSupportButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: const Color(0xFF374151),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
  final VoidCallback onToggleNative;

  const _InstructionStrip({
    required this.message,
    required this.isSuccess,
    required this.language,
    required this.showNative,
    required this.onToggleNative,
  });

  @override
  Widget build(BuildContext context) {
    final line = isSuccess
        ? equalShareResultLines.first
        : message == equalShareInstruction.japanese
        ? equalShareInstruction
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
                child: Text(
                  line.japanese,
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF166534)
                        : message == equalShareInstruction.japanese
                        ? const Color(0xFF374151)
                        : const Color(0xFF1E3A8A),
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (language != AppLanguage.japanese)
                _InlineSupportButton(
                  icon: Icons.translate_rounded,
                  label: showNative ? '日本語' : language.label,
                  onPressed: onToggleNative,
                ),
              _AudioIconButton(
                label: '操作案内の音声',
                onPressed: () {
                  LearningAudio.speakJapanese(
                    context,
                    label: '操作案内',
                    text: equalShareInstruction.japanese,
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
  final VoidCallback onToggleNative;
  final VoidCallback onAudio;

  const _DivisionResultCard({
    super.key,
    required this.selectedLanguage,
    required this.showNative,
    required this.onToggleNative,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text(
                  '同じ数ずつ分けられたね！',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selectedLanguage != AppLanguage.japanese)
                _InlineSupportButton(
                  icon: Icons.translate_rounded,
                  label: showNative ? '日本語' : selectedLanguage.label,
                  onPressed: onToggleNative,
                ),
              _AudioIconButton(label: '正解説明の音声', onPressed: onAudio),
            ],
          ),
          const SizedBox(height: 10),
          _SupportedTextLines(
            lines: equalShareResultLines.skip(1).toList(),
            language: selectedLanguage,
            showNative: showNative,
            vocabularyEntries: equalShareVocabularyEntries,
          ),
          const SizedBox(height: 12),
          _EquationLine(language: selectedLanguage),
          const SizedBox(height: 8),
          Row(
            children: [
              _AudioIconButton(
                label: '式の読み方の音声',
                onPressed: () {
                  LearningAudio.speakJapanese(
                    context,
                    label: '式の読み方',
                    text: equalShareEquationReading.japanese,
                  );
                },
              ),
              Expanded(
                child: _SupportedTextLines(
                  lines: const [equalShareEquationReading],
                  language: selectedLanguage,
                  showNative: showNative,
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

  const _EquationLine({required this.language});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EquationNumber(
            support: equalShareEquationSupports[0],
            color: const Color(0xFF2563EB),
            language: language,
          ),
          const _ResultEquationSymbol('÷'),
          _EquationNumber(
            support: equalShareEquationSupports[1],
            color: const Color(0xFFF97316),
            language: language,
          ),
          const _ResultEquationSymbol('='),
          _EquationNumber(
            support: equalShareEquationSupports[2],
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
                Text(
                  support.label,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      LearningAudio.speakJapanese(
                        context,
                        label: support.label,
                        text: support.label,
                      );
                    },
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('音声'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      height: 64,
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
            children: [
              TextSpan(
                text: '$count',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TextSpan(
                text: 'こ',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
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
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _EqualShareStoryMode({
    required this.step,
    required this.placements,
    required this.onNext,
    required this.onBack,
  });

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
          message: complete ? 'どのお皿も2こずつになりました。' : '1こずつ順番に置いていきます。',
          isSuccess: complete,
          language: AppLanguage.japanese,
          showNative: false,
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
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'いちご 6こ'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final _ in berryIds) const _CounterDot(size: 42)],
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
    return _PlateTargets(
      plateBerryIds: plateBerryIds,
      plateCounts: [for (final ids in plateBerryIds) ids.length],
      isCorrect: plateBerryIds.every((ids) => ids.length == 2),
      onMoveBerry: (_, _) {},
    );
  }
}

class _EqualShareWordsCard extends StatelessWidget {
  final AppLanguage selectedLanguage;

  const _EqualShareWordsCard({required this.selectedLanguage});

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
                    fontWeight: FontWeight.w900,
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
                  for (final item in equalShareLessonVocabulary)
                    SizedBox(
                      width: cardWidth,
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
                    Text(
                      vocabulary.word,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
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

class _VocabularyVisual extends StatelessWidget {
  final LessonVocabularyVisual visual;

  const _VocabularyVisual({required this.visual});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 76,
      child: switch (visual) {
        LessonVocabularyVisual.equalGroups => const _EqualGroupsVisual(),
        LessonVocabularyVisual.splitToPlates => const _SplitToPlatesVisual(),
        LessonVocabularyVisual.onePersonShare => const _OnePersonShareVisual(),
        LessonVocabularyVisual.countQuestion => const _CountQuestionVisual(),
      },
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.person_rounded, color: Color(0xFF4B5563), size: 30),
        SizedBox(width: 8),
        _MiniPlate(
          width: 44,
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterDot(size: 16),
              SizedBox(width: 3),
              _CounterDot(size: 16),
            ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _CounterDot(size: 22),
        SizedBox(width: 4),
        _CounterDot(size: 22),
        SizedBox(width: 8),
        Text(
          '?',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w900,
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

class _DivisionLearnStoryboard extends StatelessWidget {
  final _DivisionLearnMode mode;
  final AppLanguage selectedLanguage;
  final String nativeText;

  const _DivisionLearnStoryboard({
    required this.mode,
    required this.selectedLanguage,
    required this.nativeText,
  });

  bool get isEqualShare => mode == _DivisionLearnMode.equalShare;

  @override
  Widget build(BuildContext context) {
    final title = isEqualShare ? '例題で見てみよう' : '何人分できるかな';
    final problem = isEqualShare
        ? 'いちごが6こあります。3人で同じ数ずつ分けると、1人分は何こになりますか。'
        : 'いちごが6こあります。1人に2こずつ分けると、何人に分けられますか。';
    final action = isEqualShare
        ? '1こずつ、3人のお皿に入れます。もう一度1こずつ入れると、どのお皿も2こです。'
        : '1人に2こずつ持たせます。2こ、2こ、2こと分けると、3人分できます。';
    final reading = isEqualShare ? '6わる3は2' : '6わる2は3';
    final nativeTitle = selectedLanguage == AppLanguage.japanese
        ? '母語サポート'
        : selectedLanguage.label;

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
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF2563EB),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StoryboardPanel(
            stepLabel: '1',
            title: 'もんだい',
            child: RubyText(
              text: problem,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 21,
                height: 1.45,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StoryboardPanel(
            stepLabel: '2',
            title: '分ける動き',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 17,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _StrawberryDistribution(mode: mode),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StoryboardPanel(
            stepLabel: '3',
            title: '式で表す',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DivisionEquation(mode: mode),
                const SizedBox(height: 10),
                Text(
                  '読み方：$reading。これは「わり算」といいます。',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '九九を使って、答えをたしかめることもできます。',
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StoryboardPanel(
            stepLabel: '🌐',
            title: nativeTitle,
            child: Text(
              nativeText,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryboardPanel extends StatelessWidget {
  final String stepLabel;
  final String title;
  final Widget child;

  const _StoryboardPanel({
    required this.stepLabel,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              stepLabel,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrawberryDistribution extends StatelessWidget {
  final _DivisionLearnMode mode;

  const _StrawberryDistribution({required this.mode});

  bool get isEqualShare => mode == _DivisionLearnMode.equalShare;

  @override
  Widget build(BuildContext context) {
    final groupCount = isEqualShare ? 3 : 3;
    final berriesPerGroup = isEqualShare ? 2 : 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _AllBerriesCard(),
        for (var index = 0; index < groupCount; index++)
          _PlateCard(
            label: isEqualShare ? '${index + 1}人目のお皿' : '${index + 1}人目',
            count: berriesPerGroup,
          ),
      ],
    );
  }
}

class _AllBerriesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ぜんぶ',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [for (var i = 0; i < 6; i++) const _CounterDot()],
          ),
          const SizedBox(height: 10),
          const Text(
            '6こ',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateCard extends StatelessWidget {
  final String label;
  final int count;

  const _PlateCard({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF166534),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [for (var i = 0; i < count; i++) const _CounterDot()],
          ),
          const SizedBox(height: 8),
          Text(
            '$countこ',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
    final bodyPaint = Paint()..color = const Color(0xFFEF4444);
    final borderPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045;
    final leafPaint = Paint()..color = const Color(0xFF15803D);
    final seedPaint = Paint()..color = const Color(0xFFFFF7ED);

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

    final seeds = [
      Offset(size.width * 0.38, size.height * 0.42),
      Offset(size.width * 0.6, size.height * 0.44),
      Offset(size.width * 0.46, size.height * 0.62),
      Offset(size.width * 0.66, size.height * 0.68),
    ];
    for (final seed in seeds) {
      canvas.drawCircle(seed, size.width * 0.035, seedPaint);
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

class _DivisionEquation extends StatelessWidget {
  final _DivisionLearnMode mode;

  const _DivisionEquation({required this.mode});

  bool get isEqualShare => mode == _DivisionLearnMode.equalShare;

  @override
  Widget build(BuildContext context) {
    final divisor = isEqualShare ? '3' : '2';
    final answer = isEqualShare ? '2' : '3';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        const _EquationChip(
          value: '6',
          label: 'ぜんぶの数\nわられる数',
          color: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
        ),
        const _EquationSymbol('÷'),
        _EquationChip(
          value: divisor,
          label: isEqualShare ? '分ける人数\nわる数' : '1人分の数\nわる数',
          color: const Color(0xFFFFF7ED),
          textColor: const Color(0xFFC2410C),
        ),
        const _EquationSymbol('='),
        _EquationChip(
          value: answer,
          label: isEqualShare ? '1人分の数\n答え' : '分けられる人数\n答え',
          color: const Color(0xFFF0FDF4),
          textColor: const Color(0xFF15803D),
        ),
      ],
    );
  }
}

class _EquationChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color textColor;

  const _EquationChip({
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.24),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Baseline(
                baseline: 42,
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 12.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquationSymbol extends StatelessWidget {
  final String symbol;

  const _EquationSymbol(this.symbol);

  @override
  Widget build(BuildContext context) {
    return Text(
      symbol,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 30,
        fontWeight: FontWeight.w900,
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
    final compact = _isCompactChoice(rubyText);

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
                    ? _CompactChoiceText(text: rubyText, color: textColor)
                    : RubyText(
                        text: rubyText,
                        textAlign: TextAlign.center,
                        vocabularyEntries: vocabularyEntries,
                        language: language,
                        style: TextStyle(
                          fontSize: 19,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: textColor,
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

  bool _isCompactChoice(String value) {
    final plain = value.replaceAll(RegExp(r'\{([^|{}]+)\|([^{}]+)\}'), r'$1');
    return plain.length <= 8 &&
        RegExp(r'^[0-9０-９一二三四五六七八九十+\-−×÷=＝、.．mcm本人こまい枚]+$').hasMatch(plain);
  }
}

class _CompactChoiceText extends StatelessWidget {
  final String text;
  final Color color;

  const _CompactChoiceText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final plain = text.replaceAllMapped(
      RegExp(r'\{([^|{}]+)\|([^{}]+)\}'),
      (match) => match.group(1) ?? '',
    );
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
            height: 1,
            fontWeight: FontWeight.w900,
          ),
          children: [
            if (number != null)
              TextSpan(
                text: number,
                style: const TextStyle(fontSize: 42, letterSpacing: 0),
              ),
            TextSpan(
              text: suffix,
              style: TextStyle(
                fontSize: number == null ? 38 : 36,
                letterSpacing: 0,
              ),
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
  final AppLanguage questionLanguage;
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
                                vocabularyEntries: question.vocabularyEntries,
                                language: questionLanguage,
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
                                  vocabularyEntries: question.vocabularyEntries,
                                  language: questionLanguage,
                                  accentColor: const Color(0xFF0891B2),
                                ),
                              ],
                              if (explanationText.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _ExplanationSection(
                                  icon: Icons.tips_and_updates_rounded,
                                  title: '解き方の説明',
                                  text: explanationText,
                                  vocabularyEntries: question.vocabularyEntries,
                                  language: questionLanguage,
                                  accentColor: const Color(0xFF2563EB),
                                ),
                              ],
                              if (formulaExplanation.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _ExplanationSection(
                                  icon: Icons.functions_rounded,
                                  title: '式の説明',
                                  text: formulaExplanation,
                                  vocabularyEntries: question.vocabularyEntries,
                                  language: questionLanguage,
                                  accentColor: const Color(0xFF7C3AED),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _ExplanationSection(
                                icon: Icons.menu_book_rounded,
                                title: '日本語のポイント',
                                text: languagePoint,
                                vocabularyEntries: question.vocabularyEntries,
                                language: questionLanguage,
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
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;
  final Color accentColor;

  const _ExplanationSection({
    required this.icon,
    required this.title,
    required this.text,
    required this.vocabularyEntries,
    required this.language,
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
                RubyText(
                  text: text,
                  vocabularyEntries: vocabularyEntries,
                  language: language,
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
