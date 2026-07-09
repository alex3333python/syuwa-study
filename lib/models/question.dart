import 'app_language.dart';

class Question {
  final int id;
  final String type;
  final String unitId;
  final String promptSchoolJa;
  final String promptEasyJa;
  final Map<AppLanguage, String> promptNative;
  final List<String> choices;
  final String correctAnswerText;
  final String explanationEasyJa;
  final String explanation;
  final String formulaExplanation;
  final String languagePoint;
  final Map<AppLanguage, String> explanationNative;
  final List<String> tags;
  final String equationHint;
  final String thinkingHint;
  final String visualHint;
  final QuestionVisualType visualType;
  final String visualTitle;
  final String visualDescription;
  final String itemLabel;
  final String itemEmoji;
  final String itemUnit;
  final int? totalCount;
  final int? groupCount;
  final int? perGroupCount;
  final int? remainderCount;
  final String pictureDescription;
  final String diagramType;
  final Map<String, String> diagramData;
  final List<String> vocabulary;
  final int? grade;
  final String subject;
  final String unit;

  // Legacy fields kept so the old sign-language screens can be migrated gradually.
  final String question;
  final String signDescription;
  final int correctAnswer;
  final String? imageUrl;
  final String? videoUrl;
  final List<String>? optionImageUrls;

  const Question({
    required this.id,
    required this.type,
    this.unitId = '',
    this.promptSchoolJa = '',
    this.promptEasyJa = '',
    this.promptNative = const {},
    List<String>? choices,
    List<String>? options,
    required this.correctAnswer,
    this.correctAnswerText = '',
    this.explanationEasyJa = '',
    this.explanation = '',
    this.formulaExplanation = '',
    this.languagePoint = '',
    this.explanationNative = const {},
    this.tags = const [],
    this.equationHint = '',
    this.thinkingHint = '',
    this.visualHint = '',
    this.visualType = QuestionVisualType.none,
    this.visualTitle = '',
    this.visualDescription = '',
    this.itemLabel = '',
    this.itemEmoji = '●',
    this.itemUnit = 'こ',
    this.totalCount,
    this.groupCount,
    this.perGroupCount,
    this.remainderCount,
    this.pictureDescription = '',
    this.diagramType = '',
    this.diagramData = const {},
    this.vocabulary = const [],
    this.grade,
    this.subject = '',
    this.unit = '',
    this.question = '',
    this.signDescription = '',
    this.imageUrl,
    this.optionImageUrls,
    this.videoUrl,
  }) : choices = choices ?? options ?? const [];

  List<String> get options => choices;

  bool get hasVisual => visualType != QuestionVisualType.none;

  String get resolvedCorrectAnswerText {
    if (correctAnswerText.isNotEmpty) return correctAnswerText;
    if (correctAnswer >= 0 && correctAnswer < choices.length) {
      return choices[correctAnswer];
    }
    return '';
  }

  String get resolvedFormulaExplanation {
    if (formulaExplanation.isNotEmpty) return formulaExplanation;
    return [
      equationHint,
      thinkingHint,
    ].where((text) => text.isNotEmpty).join('\n');
  }

  String get resolvedLanguagePoint {
    if (languagePoint.isNotEmpty) return languagePoint;
    if (vocabulary.isNotEmpty) {
      return '大事な言葉: ${vocabulary.join('・')}';
    }
    return '問題文の最後を見て、何を答えるかを確かめましょう。';
  }

  String promptFor(AppLanguage language, QuestionPromptMode mode) {
    switch (mode) {
      case QuestionPromptMode.schoolJa:
        return promptSchoolJa.isNotEmpty ? promptSchoolJa : question;
      case QuestionPromptMode.easyJa:
        return promptEasyJa.isNotEmpty ? promptEasyJa : promptSchoolJa;
      case QuestionPromptMode.native:
        if (language == AppLanguage.japanese) {
          return promptEasyJa.isNotEmpty ? promptEasyJa : promptSchoolJa;
        }
        return promptNative[language] ??
            (promptEasyJa.isNotEmpty ? promptEasyJa : promptSchoolJa);
    }
  }

  String explanationFor(AppLanguage language) {
    final fallbackExplanation = explanationEasyJa.isNotEmpty
        ? explanationEasyJa
        : explanation;
    if (language == AppLanguage.japanese) {
      return fallbackExplanation;
    }
    return explanationNative[language] ?? fallbackExplanation;
  }
}

enum QuestionPromptMode { schoolJa, easyJa, native }

enum QuestionVisualType {
  none,
  divisionSharing,
  divisionRemainder,
  grouping,
  numberLine,
  fraction,
}
