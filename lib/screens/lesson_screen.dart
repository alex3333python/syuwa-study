import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/equal_share_language_support.dart';
import '../models/answer_record.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../theme/app_fonts.dart';
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
        widget.lesson.title == 'たしかめ問題' ||
        (currentStep?.id.contains('japanese') ?? false);
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
                        if (question.hasVisual &&
                            !isIndependent &&
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
              vocabularyEntries: const [],
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
              vocabularyEntries: const [],
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
  }
  return null;
}

const _timeVocabularyEntries = [
  VocabularyEntry(
    term: '時こく',
    reading: 'じこく',
    simpleJapanese: '時計がさしている、ある1つの時です。',
    translations: {AppLanguage.portuguese: 'horário'},
    exampleSentence: '8時10分は時こくです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '時間',
    reading: 'じかん',
    simpleJapanese: 'ある時こくから、別の時こくまでの長さです。',
    translations: {AppLanguage.portuguese: 'tempo / duração'},
    exampleSentence: '25分は時間です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '前',
    reading: 'まえ',
    simpleJapanese: '時計を戻して考えることばです。',
    translations: {AppLanguage.portuguese: 'antes'},
    exampleSentence: '25分前を考えます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '後',
    reading: 'あと / ご',
    simpleJapanese: '時計を進めて考えることばです。',
    translations: {AppLanguage.portuguese: 'depois'},
    exampleSentence: '20分後を考えます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '出発',
    reading: 'しゅっぱつ',
    simpleJapanese: 'ある場所を出ることです。',
    translations: {AppLanguage.portuguese: 'partida'},
    exampleSentence: '7時45分に出発します。',
    category: 'school_language',
  ),
  VocabularyEntry(
    term: '到着',
    reading: 'とうちゃく',
    simpleJapanese: '行き先につくことです。',
    translations: {AppLanguage.portuguese: 'chegada'},
    exampleSentence: '8時10分に到着します。',
    category: 'school_language',
  ),
  VocabularyEntry(
    term: '午前',
    reading: 'ごぜん',
    simpleJapanese: '夜中の12時から、正午までの時こくにつける言葉です。',
    translations: {AppLanguage.portuguese: 'da manhã / a.m.'},
    exampleSentence: '午前7時40分に出発します。',
    category: 'time_language',
  ),
  VocabularyEntry(
    term: '午後',
    reading: 'ごご',
    simpleJapanese: '正午をすぎたあとの時こくにつける言葉です。',
    translations: {AppLanguage.portuguese: 'da tarde / p.m.'},
    exampleSentence: '午後3時40分に始まります。',
    category: 'time_language',
  ),
  VocabularyEntry(
    term: '秒',
    reading: 'びょう',
    simpleJapanese: '分より短い時間の単位です。',
    translations: {AppLanguage.portuguese: 'segundo'},
    exampleSentence: '1分は60秒です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '秒針',
    reading: 'びょうしん',
    simpleJapanese: '秒を表す時計の針です。',
    translations: {AppLanguage.portuguese: 'ponteiro dos segundos'},
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
  int _minuteOffset = 0;

  static const _lastPage = 1;

  void _previous() {
    if (_page == 0) return;
    setState(() {
      _page--;
      _minuteOffset = 0;
    });
  }

  void _next() {
    if (_page == _lastPage) return;
    setState(() {
      _page++;
      _minuteOffset = 0;
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
          },
        ),
        guide: SupportLine(
          japanese: '時計を30分動かしてみよう。',
          ruby: '{時計|とけい}を30{分|ぷん}{動|うご}かしてみよう。',
          native: {AppLanguage.portuguese: 'Mova o relógio 30 minutos.'},
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
          },
        ),
        guide: SupportLine(
          japanese: '午後4時50分まで時計を動かしてみよう。',
          ruby: '{午後|ごご}4{時|じ}50{分|ぷん}まで{時計|とけい}を{動|うご}かしてみよう。',
          native: {AppLanguage.portuguese: 'Mova o relógio até 4:50 da tarde.'},
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
          _showNative = !_showNative;
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
          ),
          const SizedBox(height: 12),
          _SupportedTextLines(
            lines: [page.guide],
            language: widget.selectedLanguage,
            showNative: _showNative,
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
            _TimeResultBox(page: page),
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
          ),
          const SizedBox(height: 20),
          switch (_page) {
            0 => const _SecondHandPanel(),
            _ => const _MinuteSecondPanel(),
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              _AnalogTimeClock(
                startTotalMinutes: scenario.hour * 60 + scenario.minute,
                totalMinutes: currentTotal,
                progress: scenario.targetOffset == 0
                    ? 0
                    : offset.abs() / scenario.targetOffset.abs(),
              ),
              Column(
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
                      scenario.targetOffset < 0
                          ? '時計を戻せたね。'
                          : scenario.completionMessage,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: locked ? null : () => onChangeOffset(-5),
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('5分もどす'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: locked ? null : () => onChangeOffset(5),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('5分すすめる'),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _TimeResultBox extends StatelessWidget {
  final _TimeLearnPage page;

  const _TimeResultBox({required this.page});

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
          const Text(
            '答え',
            style: TextStyle(
              color: Color(0xFF047857),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.answer,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              color: Color(0xFF111827),
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.explanation,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < page.splitLabels.length; i++)
                _SplitClockCard(
                  label: page.splitLabels[i],
                  startTotalMinutes:
                      page.scenario.hour * 60 +
                      page.scenario.minute +
                      page.splitMinutes
                          .take(i)
                          .fold(0, (sum, value) => sum + value),
                  minutes: page.splitMinutes[i],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TimeRuler(
            startTotalMinutes: page.scenario.hour * 60 + page.scenario.minute,
            labels: page.timelineLabels,
            spans: page.splitLabels,
            splitMinutes: page.splitMinutes,
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
  const _SecondHandPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Wrap(
          spacing: 18,
          runSpacing: 18,
          alignment: WrapAlignment.center,
          children: [_SecondClockCard(), _StopwatchSecondCard()],
        ),
        const SizedBox(height: 18),
        const Text(
          '60秒 = 1分',
          style: TextStyle(
            fontFamily: AppFonts.display,
            color: Color(0xFF2563EB),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '秒針が1目もり進むと1秒。ストップウォッチの数字が1ふえると1秒です。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 17,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
  const _MinuteSecondPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
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
          const Text(
            '1分は60秒。だから、1分20秒は80秒です。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111827),
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
  int? _selectedProduct;
  bool _showNative = false;

  static const int _lastPage = 5;

  void _speak(String label, String text) {
    LearningAudio.speakJapanese(context, label: label, text: text);
  }

  void _previous() {
    if (_page == 0) return;
    setState(() {
      _page--;
      _selectedProduct = null;
    });
  }

  void _next() {
    if (_page == _lastPage) return;
    setState(() {
      _page++;
      _selectedProduct = null;
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
      1 => 'これまでの分け方',
      2 => '同じ図をかけ算で見る',
      3 => '同じ数がつながっているね',
      4 => '□に入る数を探そう',
      _ => 'まとめ',
    };
  }

  String get _plainJapanese {
    return switch (_page) {
      0 => 'かけ算を使って、わり算の答えを見つけよう。わり算とかけ算には、どんなつながりがあるかな。',
      1 => 'クッキーが12こあります。3人に同じ数ずつ分けると、1人分は4こです。12わる3は4です。',
      2 => 'こんどは、分けたあとの図を見てみよう。1人に4こずつあります。4こずつが3人分あるので、3かける4は12です。',
      3 => '同じ3つの数を使って、わり算とかけ算の式を作ることができます。',
      4 => '3に何をかけると15になるかな。',
      _ => 'かけ算を使うと、わり算の答えが見つかるね。',
    };
  }

  Widget _buildPage() {
    return switch (_page) {
      0 => _buildAimPage(),
      1 => _buildDivisionReviewPage(),
      2 => _buildMultiplicationViewPage(),
      3 => _buildEquationConnectionPage(),
      4 => _buildBoxPracticePage(),
      _ => _buildSummaryPage(),
    };
  }

  Widget _buildAimPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: 'わり算の答えは、かけ算を使って見つけられます。',
              ruby: 'わり{算|ざん}の{答え|こたえ}は、かけ{算|ざん}を{使|つか}って{見|み}つけられます。',
              native: {
                AppLanguage.portuguese:
                    'A resposta da divisão pode ser encontrada usando a multiplicação.',
              },
            ),
            SupportLine(
              japanese: '同じ図を、わり算とかけ算の2つの式で見てみよう。',
              ruby: '{同|おな}じ{図|ず}を、わり{算|ざん}とかけ{算|ざん}の2つの{式|しき}で{見て|みて}みよう。',
              native: {
                AppLanguage.portuguese:
                    'Vamos olhar o mesmo desenho com duas contas: divisão e multiplicação.',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        const _CookieShareDiagram(total: 12, groups: 3, each: 4),
      ],
    );
  }

  Widget _buildDivisionReviewPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: 'クッキーが12こあります。',
              ruby: 'クッキーが12こあります。',
              native: {AppLanguage.portuguese: 'Há 12 biscoitos.'},
            ),
            SupportLine(
              japanese: '3人に同じ数ずつ分けると、1人分は何こになるかな？',
              ruby:
                  '3{人|にん}に{同|おな}じ{数|かず}ずつ{分|わ}けると、{1人|ひとり}{分|ぶん}は{何こ|なんこ}になるかな？',
              native: {
                AppLanguage.portuguese:
                    'Se dividirmos igualmente entre 3 pessoas, quantos biscoitos cada pessoa recebe?',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        const _CookieShareDiagram(total: 12, groups: 3, each: 4),
        const SizedBox(height: 18),
        const _LargeEquation(
          parts: [
            _EquationPart('12', Color(0xFF2563EB), 'ぜんぶの数'),
            _EquationPart('÷', Color(0xFF111827), ''),
            _EquationPart('3', Color(0xFFF97316), '人数'),
            _EquationPart('=', Color(0xFF111827), ''),
            _EquationPart('4', Color(0xFF059669), '1人分'),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiplicationViewPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: 'こんどは、分けたあとの図を見てみよう。',
              ruby: 'こんどは、{分|わ}けたあとの{図|ず}を{見|み}てみよう。',
              native: {
                AppLanguage.portuguese:
                    'Agora vamos olhar o desenho depois de dividir.',
              },
            ),
            SupportLine(
              japanese: '4こずつが3人分あるので、ぜんぶで12こです。',
              ruby: '4こずつが3{人|にん}{分|ぶん}あるので、{全部|ぜんぶ}で12こです。',
              native: {
                AppLanguage.portuguese:
                    'Há 3 grupos de 4, então são 12 biscoitos no total.',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        const _CookieShareDiagram(total: 12, groups: 3, each: 4),
        const SizedBox(height: 18),
        const _LargeEquation(
          parts: [
            _EquationPart('3', Color(0xFFF97316), '人数'),
            _EquationPart('×', Color(0xFF111827), ''),
            _EquationPart('4', Color(0xFF059669), '1人分'),
            _EquationPart('=', Color(0xFF111827), ''),
            _EquationPart('12', Color(0xFF2563EB), 'ぜんぶの数'),
          ],
        ),
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
                  '{同|おな}じ3つの{数|かず}を{使|つか}って、わり{算|ざん}とかけ{算|ざん}の{式|しき}を{作|つく}ることができます。',
              native: {
                AppLanguage.portuguese:
                    'Com os mesmos três números, podemos fazer uma conta de divisão e uma de multiplicação.',
              },
            ),
            SupportLine(
              japanese: 'わり算の答えは、かけ算を使って見つけられます。',
              ruby: 'わり{算|ざん}の{答え|こたえ}は、かけ{算|ざん}を{使|つか}って{見|み}つけられます。',
              native: {
                AppLanguage.portuguese:
                    'A resposta da divisão pode ser encontrada usando a multiplicação.',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        const _EquationPairPanel(),
      ],
    );
  }

  Widget _buildBoxPracticePage() {
    final choices = const [
      ('3 × 3 = 9', false),
      ('3 × 4 = 12', false),
      ('3 × 5 = 15', true),
      ('3 × 6 = 18', false),
    ];
    final isCorrect = _selectedProduct == 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: '3に何をかけると、15になるかな？',
              ruby: '3に{何|なに}をかけると、15になるかな？',
              native: {
                AppLanguage.portuguese: 'Que número multiplicado por 3 dá 15?',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
        const SizedBox(height: 18),
        _BoxEquationPair(answer: isCorrect ? '5' : '□'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < choices.length; i++)
              _MultiplicationChoiceCard(
                label: choices[i].$1,
                selected: _selectedProduct == i,
                correct: _selectedProduct == i && choices[i].$2,
                onTap: () {
                  setState(() {
                    _selectedProduct = i;
                  });
                },
              ),
          ],
        ),
        if (_selectedProduct != null) ...[
          const SizedBox(height: 16),
          _ResultMessage(
            success: isCorrect,
            text: isCorrect
                ? '3 × 5 = 15だから、15 ÷ 3 = 5です。'
                : '15になるかけ算を探してみよう。',
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EquationPairPanel(),
        const SizedBox(height: 18),
        _LearnTextBlock(
          lines: const [
            SupportLine(
              japanese: 'わられる数になるかけ算を探すと、わり算の答えが分かります。',
              ruby:
                  'わられる{数|かず}になるかけ{算|ざん}を{探|さが}すと、わり{算|ざん}の{答え|こたえ}が{分|わ}かります。',
              native: {
                AppLanguage.portuguese:
                    'Procure a multiplicação que dá o número dividido; assim você encontra a resposta da divisão.',
              },
            ),
          ],
          language: widget.selectedLanguage,
          showNative: _showNative,
        ),
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

  static const _lastPage = 4;

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
      3 => 'あまりは、わる数より小さい',
      _ => 'まとめ',
    };
  }

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: 'いちごが7こあります。',
          ruby: 'いちごが7こあります。',
          native: {AppLanguage.portuguese: 'Há 7 morangos.'},
        ),
        SupportLine(
          japanese: '3人で同じ数ずつ分けると、1人分は2こで、1こ残ります。',
          ruby:
              '3{人|にん}で{同|おな}じ{数|かず}ずつ{分|わ}けると、{1人|ひとり}{分|ぶん}は2こで、1こ{残|のこ}ります。',
          native: {
            AppLanguage.portuguese:
                'Dividindo igualmente entre 3 pessoas, cada pessoa recebe 2 e sobra 1.',
          },
        ),
      ],
      1 => const [
        SupportLine(
          japanese: 'このことを、7 ÷ 3 = 2 あまり 1 と書きます。',
          ruby: 'このことを、7 ÷ 3 = 2 あまり 1 と{書|か}きます。',
          native: {
            AppLanguage.portuguese: 'Escrevemos assim: 7 ÷ 3 = 2, resto 1.',
          },
        ),
        SupportLine(
          japanese: '「2」は1人分、「1」はあまりです。',
          ruby: '「2」は{1人|ひとり}{分|ぶん}、「1」はあまりです。',
          native: {
            AppLanguage.portuguese:
                'O 2 é a quantidade para cada pessoa. O 1 é o resto.',
          },
        ),
      ],
      2 => const [
        SupportLine(
          japanese: '3人に2こずつあるので、3 × 2 = 6 です。',
          ruby: '3{人|にん}に2こずつあるので、3 × 2 = 6 です。',
          native: {
            AppLanguage.portuguese:
                'Como há 2 para cada uma das 3 pessoas, 3 × 2 = 6.',
          },
        ),
        SupportLine(
          japanese: '6こ使って、1こ残るので、3 × 2 + 1 = 7 です。',
          ruby: '6こ{使|つか}って、1こ{残|のこ}るので、3 × 2 + 1 = 7 です。',
          native: {
            AppLanguage.portuguese: 'Usamos 6 e sobra 1, então 3 × 2 + 1 = 7.',
          },
        ),
      ],
      3 => const [
        SupportLine(
          japanese: '3人で分けると、あまりは0、1、2のどれかです。',
          ruby: '3{人|にん}で{分|わ}けると、あまりは0、1、2のどれかです。',
          native: {
            AppLanguage.portuguese:
                'Ao dividir entre 3 pessoas, o resto pode ser 0, 1 ou 2.',
          },
        ),
        SupportLine(
          japanese: 'あまりが3こになったら、もう1人分を作れます。',
          ruby: 'あまりが3こになったら、もう{1人|ひとり}{分|ぶん}を{作|つく}れます。',
          native: {
            AppLanguage.portuguese:
                'Se sobrassem 3, daria para formar mais uma parte.',
          },
        ),
      ],
      _ => const [
        SupportLine(
          japanese: 'あまりのあるわり算は、九九を使って考えられます。',
          ruby: 'あまりのあるわり{算|ざん}は、九九を{使|つか}って{考|かんが}えられます。',
          native: {
            AppLanguage.portuguese:
                'A divisão com resto pode ser pensada usando a tabuada.',
          },
        ),
        SupportLine(
          japanese: 'あまりは、いつもわる数より小さくなります。',
          ruby: 'あまりは、いつもわる{数|かず}より{小|ちい}さくなります。',
          native: {
            AppLanguage.portuguese: 'O resto é sempre menor que o divisor.',
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
        ),
        const SizedBox(height: 18),
        switch (_page) {
          0 => const _RemainderShareDiagram(
            total: 7,
            groups: 3,
            each: 2,
            remainder: 1,
            itemEmoji: '🍓',
          ),
          1 => const _RemainderEquationPanel(),
          2 => const _RemainderMultiplicationPanel(),
          3 => const _RemainderGrowthPanel(),
          _ => const _RemainderSummaryPanel(),
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
      1 => '9人なら、長いすは何台？',
      2 => 'もう1台いるね',
      _ => 'まとめ',
    };
  }

  List<SupportLine> get _pageLines {
    return switch (_page) {
      0 => const [
        SupportLine(
          japanese: '4人がけの長いすがあります。',
          ruby: '4{人|にん}がけの{長|なが}いすがあります。',
          native: {AppLanguage.portuguese: 'Há bancos para 4 pessoas.'},
        ),
        SupportLine(
          japanese: '9人がすわるには、長いすは何台いるかな？',
          ruby: '9{人|にん}がすわるには、{長|なが}いすは{何台|なんだい}いるかな？',
          native: {
            AppLanguage.portuguese:
                'Para 9 pessoas se sentarem, quantos bancos são necessários?',
          },
        ),
      ],
      1 => const [
        SupportLine(
          japanese: '9 ÷ 4 = 2 あまり 1 です。',
          ruby: '9 ÷ 4 = 2 あまり 1 です。',
          native: {AppLanguage.portuguese: '9 ÷ 4 = 2, resto 1.'},
        ),
        SupportLine(
          japanese: '2台では8人までなので、1人がすわれません。',
          ruby: '2{台|だい}では8{人|にん}までなので、1{人|ひとり}がすわれません。',
          native: {
            AppLanguage.portuguese:
                'Com 2 bancos cabem 8 pessoas, então 1 pessoa fica sem sentar.',
          },
        ),
      ],
      2 => const [
        SupportLine(
          japanese: 'あまった1人もすわるので、もう1台いります。',
          ruby: 'あまった1{人|ひとり}もすわるので、もう1{台|だい}いります。',
          native: {
            AppLanguage.portuguese:
                'A pessoa que sobrou também precisa se sentar, então precisamos de mais 1 banco.',
          },
        ),
        SupportLine(
          japanese: '答えは3台です。',
          ruby: '{答え|こたえ}は3{台|だい}です。',
          native: {AppLanguage.portuguese: 'A resposta é 3 bancos.'},
        ),
      ],
      _ => const [
        SupportLine(
          japanese: 'あまりが出たら、問題の場面に戻って考えます。',
          ruby: 'あまりが{出|で}たら、{問題|もんだい}の{場面|ばめん}に{戻|もど}って{考|かんが}えます。',
          native: {
            AppLanguage.portuguese:
                'Quando aparece resto, voltamos à situação do problema e pensamos.',
          },
        ),
        SupportLine(
          japanese: '人がすわる問題では、あまった人のために1つ増やすことがあります。',
          ruby: '{人|ひと}がすわる{問題|もんだい}では、あまった{人|ひと}のために1つ{増|ふ}やすことがあります。',
          native: {
            AppLanguage.portuguese:
                'Em problemas com pessoas sentando, às vezes aumentamos 1 para quem sobrou.',
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
        ),
        const SizedBox(height: 18),
        switch (_page) {
          0 => const _BenchRemainderDiagram(benchCount: 2, showWaiting: true),
          1 => const _BenchRemainderDiagram(benchCount: 2, showWaiting: true),
          2 => const _BenchRemainderDiagram(benchCount: 3, showWaiting: false),
          _ => const _RemainderContextSummaryPanel(),
        },
      ],
    );
  }
}

class _RemainderLearnShell extends StatelessWidget {
  final IconData icon;
  final String title;
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
              _LearnHeaderIcon(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
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
    );
  }
}

const _remainderLearnVocabulary = [
  ...equalShareVocabularyEntries,
  VocabularyEntry(
    term: 'あまり',
    reading: 'あまり',
    simpleJapanese: '分けたあとに残る数です。',
    translations: {AppLanguage.portuguese: 'resto / sobra'},
    exampleSentence: '7 ÷ 3 = 2 あまり 1 です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'わる数',
    reading: 'わるかず',
    simpleJapanese: '何こずつ、または何人で分けるかを表す数です。',
    translations: {AppLanguage.portuguese: 'divisor'},
    exampleSentence: '7 ÷ 3 の3は、わる数です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'わられる数',
    reading: 'わられるかず',
    simpleJapanese: 'はじめにある全部の数です。',
    translations: {AppLanguage.portuguese: 'número que será dividido'},
    exampleSentence: '7 ÷ 3 の7は、わられる数です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '残ります',
    reading: 'のこる',
    simpleJapanese: 'まだある、という意味です。',
    translations: {AppLanguage.portuguese: 'sobra / fica'},
    exampleSentence: '1こ残ります。',
    category: 'math_language',
  ),
];

const _remainderContextVocabulary = [
  VocabularyEntry(
    term: '長いす',
    reading: 'ながいす',
    simpleJapanese: '何人かがいっしょに座れるいすです。',
    translations: {AppLanguage.portuguese: 'banco'},
    exampleSentence: '4人がけの長いすがあります。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: '何台',
    reading: 'なんだい',
    simpleJapanese: '車や長いすなどの数を聞く言い方です。',
    translations: {AppLanguage.portuguese: 'quantos'},
    exampleSentence: '長いすは何台いりますか。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '必要',
    reading: 'ひつよう',
    simpleJapanese: 'なくてはならないことです。',
    translations: {AppLanguage.portuguese: 'necessário'},
    exampleSentence: 'もう1台必要です。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '場面',
    reading: 'ばめん',
    simpleJapanese: '問題で起きていることです。',
    translations: {AppLanguage.portuguese: 'situação'},
    exampleSentence: '問題の場面に戻って考えます。',
    category: 'school_japanese',
  ),
];

class _RemainderShareDiagram extends StatelessWidget {
  final int total;
  final int groups;
  final int each;
  final int remainder;
  final String itemEmoji;

  const _RemainderShareDiagram({
    required this.total,
    required this.groups,
    required this.each,
    required this.remainder,
    required this.itemEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RemainderItemRow(
            label: '全部で$totalこ',
            count: total,
            itemEmoji: itemEmoji,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < groups; i++)
                _RemainderGroupBox(
                  label: '${i + 1}人目',
                  count: each,
                  itemEmoji: itemEmoji,
                ),
              _RemainderGroupBox(
                label: 'あまり',
                count: remainder,
                itemEmoji: itemEmoji,
                isRemainder: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemainderItemRow extends StatelessWidget {
  final String label;
  final int count;
  final String itemEmoji;

  const _RemainderItemRow({
    required this.label,
    required this.count,
    required this.itemEmoji,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < count; i++)
                _RemainderItemDot(itemEmoji: itemEmoji),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemainderGroupBox extends StatelessWidget {
  final String label;
  final int count;
  final String itemEmoji;
  final bool isRemainder;

  const _RemainderGroupBox({
    required this.label,
    required this.count,
    required this.itemEmoji,
    this.isRemainder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRemainder ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRemainder
              ? const Color(0xFFFDE68A)
              : const Color(0xFFA7F3D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isRemainder
                  ? const Color(0xFF92400E)
                  : const Color(0xFF065F46),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < count; i++)
                _RemainderItemDot(itemEmoji: itemEmoji),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemainderItemDot extends StatelessWidget {
  final String itemEmoji;

  const _RemainderItemDot({required this.itemEmoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(itemEmoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _RemainderEquationPanel extends StatelessWidget {
  const _RemainderEquationPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LargeEquation(
          parts: [
            _EquationPart('7', Color(0xFF2563EB), '全部の数'),
            _EquationPart('÷', Color(0xFF111827), ''),
            _EquationPart('3', Color(0xFFF97316), 'わる数'),
            _EquationPart('=', Color(0xFF111827), ''),
            _EquationPart('2', Color(0xFF059669), '1人分'),
            _EquationPart('あまり', Color(0xFF111827), ''),
            _EquationPart('1', Color(0xFFB45309), 'あまり'),
          ],
        ),
        SizedBox(height: 18),
        _RemainderShareDiagram(
          total: 7,
          groups: 3,
          each: 2,
          remainder: 1,
          itemEmoji: '🍓',
        ),
      ],
    );
  }
}

class _RemainderMultiplicationPanel extends StatelessWidget {
  const _RemainderMultiplicationPanel();

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
          _LargeEquation(
            parts: [
              _EquationPart('3', Color(0xFFF97316), '1つ分'),
              _EquationPart('×', Color(0xFF111827), ''),
              _EquationPart('2', Color(0xFF059669), 'いくつ分'),
              _EquationPart('+', Color(0xFF111827), ''),
              _EquationPart('1', Color(0xFFB45309), 'あまり'),
              _EquationPart('=', Color(0xFF111827), ''),
              _EquationPart('7', Color(0xFF2563EB), '全部の数'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemainderGrowthPanel extends StatelessWidget {
  const _RemainderGrowthPanel();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('6 ÷ 3', '2 あまり 0'),
      ('7 ÷ 3', '2 あまり 1'),
      ('8 ÷ 3', '2 あまり 2'),
      ('9 ÷ 3', '3 あまり 0'),
    ];
    return Column(
      children: [
        for (final row in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Text(
                  row.$1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 16),
                const Text('=', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 16),
                Text(
                  row.$2,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
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

  const _BenchRemainderDiagram({
    required this.benchCount,
    required this.showWaiting,
  });

  @override
  Widget build(BuildContext context) {
    final seated = benchCount == 2 ? 8 : 9;
    final waiting = showWaiting ? 1 : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < benchCount; i++)
            _BenchBox(index: i + 1, people: i == 2 ? 1 : 4),
          if (waiting > 0) const _WaitingPersonBox(),
          if (seated < 9)
            const SizedBox.shrink()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '9人みんなすわれます',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BenchBox extends StatelessWidget {
  final int index;
  final int people;

  const _BenchBox({required this.index, required this.people});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index台目',
            style: const TextStyle(
              color: Color(0xFF065F46),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < people; i++)
                const Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Color(0xFF4B5563),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingPersonBox extends StatelessWidget {
  const _WaitingPersonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        children: [
          Text(
            'まだすわれない人',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Icon(Icons.person_rounded, size: 30, color: Color(0xFF92400E)),
        ],
      ),
    );
  }
}

class _RemainderContextSummaryPanel extends StatelessWidget {
  const _RemainderContextSummaryPanel();

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
            '9 ÷ 4 = 2 あまり 1',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '2台では1人すわれないので、答えは3台です。',
            style: TextStyle(
              color: Color(0xFF065F46),
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
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
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$index人目',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [for (var i = 0; i < count; i++) const _CookieDot()],
          ),
        ],
      ),
    );
  }
}

class _CookieDot extends StatelessWidget {
  const _CookieDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text('🍪', style: TextStyle(fontSize: 18)),
    );
  }
}

class _EquationPart {
  final String text;
  final Color color;
  final String label;

  const _EquationPart(this.text, this.color, this.label);
}

class _LargeEquation extends StatelessWidget {
  final List<_EquationPart> parts;

  const _LargeEquation({required this.parts});

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
              ],
            ],
          ),
      ],
    );
  }
}

class _EquationPairPanel extends StatelessWidget {
  const _EquationPairPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LargeEquation(
            parts: [
              _EquationPart('12', Color(0xFF2563EB), 'ぜんぶの数'),
              _EquationPart('÷', Color(0xFF111827), ''),
              _EquationPart('3', Color(0xFFF97316), '人数'),
              _EquationPart('=', Color(0xFF111827), ''),
              _EquationPart('4', Color(0xFF059669), '1人分'),
            ],
          ),
          SizedBox(height: 20),
          _LargeEquation(
            parts: [
              _EquationPart('3', Color(0xFFF97316), '人数'),
              _EquationPart('×', Color(0xFF111827), ''),
              _EquationPart('4', Color(0xFF059669), '1人分'),
              _EquationPart('=', Color(0xFF111827), ''),
              _EquationPart('12', Color(0xFF2563EB), 'ぜんぶの数'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoxEquationPair extends StatelessWidget {
  final String answer;

  const _BoxEquationPair({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BoxEquationText(text: '15 ÷ 3 = $answer'),
          const SizedBox(height: 12),
          _BoxEquationText(text: '3 × $answer = 15'),
        ],
      ),
    );
  }
}

class _BoxEquationText extends StatelessWidget {
  final String text;

  const _BoxEquationText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 28,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _MultiplicationChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final VoidCallback onTap;

  const _MultiplicationChoiceCard({
    required this.label,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct
        ? const Color(0xFFDCFCE7)
        : selected
        ? const Color(0xFFFFF7ED)
        : Colors.white;
    return SizedBox(
      width: 190,
      height: 76,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultMessage extends StatelessWidget {
  final bool success;
  final String text;

  const _ResultMessage({required this.success, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
            color: success ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w800,
                color: success
                    ? const Color(0xFF065F46)
                    : const Color(0xFF92400E),
              ),
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
  bool _showStory = false;
  int _storyStep = 0;
  bool _showResult = false;
  bool _showProblemNative = false;
  bool _showInstructionNative = false;
  bool _showResultNative = false;
  final List<int?> _berryOwners = List<int?>.filled(6, null);

  _ZeroOneScenario get _scenario => _zeroOneScenarios[_scenarioIndex];

  void _selectScenario(int index) {
    setState(() {
      _scenarioIndex = index;
      _showStory = false;
      _storyStep = 0;
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
      _storyStep = 0;
      for (var i = 0; i < _berryOwners.length; i++) {
        _berryOwners[i] = null;
      }
    });
  }

  void _showAnswer() {
    setState(() {
      _showResult = true;
      if (_scenario.kind == _ZeroOneScenarioKind.divideByOne) {
        for (var i = 0; i < _berryOwners.length; i++) {
          _berryOwners[i] = 0;
        }
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
                        fontWeight: FontWeight.w900,
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
                    _showResult = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ZeroOneScenarioTabs(
            selectedIndex: _scenarioIndex,
            onChanged: _selectScenario,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _showStory
                ? _ZeroOneStoryBoard(
                    key: ValueKey('story-$_scenarioIndex-$_storyStep'),
                    scenario: _scenario,
                    step: _storyStep,
                    selectedLanguage: widget.selectedLanguage,
                    showInstructionNative: _showInstructionNative,
                    onToggleInstructionNative: () {
                      setState(() {
                        _showInstructionNative = !_showInstructionNative;
                      });
                    },
                    onNext: () {
                      setState(() {
                        _storyStep = (_storyStep + 1).clamp(
                          0,
                          _scenario.maxStoryStep,
                        );
                        _showResult = _storyStep == _scenario.maxStoryStep;
                      });
                    },
                    onBack: () {
                      setState(() {
                        _storyStep = (_storyStep - 1).clamp(
                          0,
                          _scenario.maxStoryStep,
                        );
                        _showResult = _storyStep == _scenario.maxStoryStep;
                      });
                    },
                  )
                : _ZeroOneDragBoard(
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
                    onShowAnswer: _showAnswer,
                    onReset: _resetScenario,
                  ),
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
          'いちごが6こあります。{1人|ひとり}で{同|おな}じ{数|かず}ずつ{分|わ}けると、{1人|ひとり}{分|ぶん}は{何|なん}こになりますか。',
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
          '{1人|ひとり}で{分|わ}けるので、6このいちごは{全部|ぜんぶ}その{人|ひと}がもらいます。だから、{1人|ひとり}{分|ぶん}は6こです。',
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
      ruby: '1でわると、{答|こた}えはもとの{数|かず}になります。',
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
          'いちごが0こあります。3{人|にん}で{同|おな}じ{数|かず}ずつ{分|わ}けると、{1人|ひとり}{分|ぶん}は{何|なん}こになりますか。',
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
      ruby: 'いちごは0こなので、{配|くば}るものがありません。3{人|にん}のお{皿|さら}は、どれも0こです。',
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
      ruby: '0を{人数|にんずう}でわると、{答|こた}えは0になります。',
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
      ruby: 'いちごが6こあります。0{人|にん}で{同|おな}じ{数|かず}ずつ{分|わ}けることはできますか。',
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
          'いちごは6こありますが、{分|わ}ける{人|ひと}が0{人|にん}です。だれのお{皿|さら}にも{入|い}れられないので、{分|わ}けることはできません。',
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
  final VoidCallback onShowAnswer;
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
    required this.onShowAnswer,
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
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onShowAnswer,
              style: FilledButton.styleFrom(
                minimumSize: const Size(128, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'たしかめる',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
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
    this.resultLines = equalShareResultLines,
    this.equationReading = equalShareEquationReading,
    this.equationSupports = equalShareEquationSupports,
    this.vocabularyEntries = equalShareVocabularyEntries,
    this.storyOrder = const [0, 1, 2, 0, 1, 2],
    this.successMessage = '同じ数ずつ分けられたね！',
    this.retryMessage = '同じ数になっているかな？ お皿ごとの数を見てみよう。',
    this.storyMessage = '1こずつ順番に置いていきます。',
    this.storyCompleteMessage = 'どのお皿も2こずつになりました。',
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

  List<int> _storyPlateForStep(int step) {
    final placements = <int>[];
    for (var i = 0; i < _berryCount; i++) {
      placements.add(i < step ? widget.storyOrder[i] : -1);
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
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
              storyMessage: widget.storyMessage,
              storyCompleteMessage: widget.storyCompleteMessage,
              resultLines: widget.resultLines,
              equationReading: widget.equationReading,
              equationSupports: widget.equationSupports,
              vocabularyEntries: widget.vocabularyEntries,
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
              instructionLine: widget.instructionLine,
              successLine: widget.resultLines.first,
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
            text: line.rubyText,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (language != AppLanguage.japanese) ...[
          _SupportIconButton(
            icon: Icons.translate_rounded,
            label: translateLabel,
            selected: showNative,
            onPressed: onToggleNative,
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
    return Tooltip(
      message: label,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
            foregroundColor: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFF374151),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          icon: Icon(icon, size: 21),
        ),
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
  final SupportLine instructionLine;
  final SupportLine? successLine;
  final VoidCallback onToggleNative;

  const _InstructionStrip({
    required this.message,
    required this.isSuccess,
    required this.language,
    required this.showNative,
    this.instructionLine = equalShareInstruction,
    this.successLine,
    required this.onToggleNative,
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
                child: Text(
                  line.japanese,
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF166534)
                        : message == instructionLine.japanese
                        ? const Color(0xFF374151)
                        : const Color(0xFF1E3A8A),
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
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
                  LearningAudio.speakJapanese(
                    context,
                    label: '操作案内',
                    text: line.japanese,
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
                child: Text(
                  resultLines.first.japanese,
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
            vocabularyEntries: vocabularyEntries,
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
    this.storyMessage = '1こずつ順番に置いていきます。',
    this.storyCompleteMessage = 'どのお皿も2こずつになりました。',
    this.resultLines = equalShareResultLines,
    this.equationReading = equalShareEquationReading,
    this.equationSupports = equalShareEquationSupports,
    this.vocabularyEntries = equalShareVocabularyEntries,
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
          message: complete ? storyCompleteMessage : storyMessage,
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

  const _EqualShareWordsCard({
    required this.selectedLanguage,
    this.vocabularyItems = equalShareLessonVocabulary,
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
                  for (final item in vocabularyItems)
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
    return Tooltip(
      message: '$word の音声',
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          onPressed: () {
            final normalizedReading = reading.replaceAll(' ', '');
            LearningAudio.speakJapanese(
              context,
              label: word,
              text: normalizedReading.isEmpty ? word : normalizedReading,
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF4B5563),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          icon: const Icon(Icons.volume_up_rounded, size: 22),
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
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _DiagramAnswerCard({
    required this.diagram,
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

  const _ChoiceEqualShareDiagram({
    required this.groups,
    required this.each,
    required this.labelSuffix,
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

  const _MiniPersonShareBox({
    required this.index,
    required this.count,
    required this.labelSuffix,
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
            spacing: 4,
            runSpacing: 4,
            children: [for (var i = 0; i < count; i++) const _MiniSealDot()],
          ),
        ],
      ),
    );
  }
}

class _MiniSealDot extends StatelessWidget {
  const _MiniSealDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF60A5FA),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 3)],
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

  @override
  void initState() {
    super.initState();
    showNative = hasNativeExplanation;
  }

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
          if (widget.question.hasVisual) ...[
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
