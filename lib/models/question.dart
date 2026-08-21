import 'app_language.dart';

class Question {
  final int id;
  final String type;
  final String unitId;
  final String promptSchoolJa;
  final String promptEasyJa;
  final Map<AppLanguage, String> promptNative;
  final String questionTextRuby;
  final List<String> choices;
  final List<String> choicesRuby;
  final String correctAnswerText;
  final String correctAnswerTextRuby;
  final String explanationEasyJa;
  final String explanation;
  final String explanationRuby;
  final String formulaExplanation;
  final String formulaExplanationRuby;
  final String languagePoint;
  final String languagePointRuby;
  final List<VocabularyEntry> vocabularyEntries;
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
  final List<Map<String, String>> choiceDiagramData;
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
    this.questionTextRuby = '',
    List<String>? choices,
    List<String>? options,
    this.choicesRuby = const [],
    required this.correctAnswer,
    this.correctAnswerText = '',
    this.correctAnswerTextRuby = '',
    this.explanationEasyJa = '',
    this.explanation = '',
    this.explanationRuby = '',
    this.formulaExplanation = '',
    this.formulaExplanationRuby = '',
    this.languagePoint = '',
    this.languagePointRuby = '',
    this.vocabularyEntries = const [],
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
    this.choiceDiagramData = const [],
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

  bool get hasVisual =>
      visualType != QuestionVisualType.none || diagramType.isNotEmpty;

  String promptRubyFor(AppLanguage language, QuestionPromptMode mode) {
    if (mode == QuestionPromptMode.native) {
      return promptFor(language, mode);
    }
    if (questionTextRuby.isNotEmpty) return questionTextRuby;
    return promptFor(language, mode);
  }

  List<String> get resolvedChoicesRuby {
    return [
      for (var i = 0; i < choices.length; i++)
        i < choicesRuby.length && choicesRuby[i].isNotEmpty
            ? choicesRuby[i]
            : choices[i],
    ];
  }

  String get resolvedCorrectAnswerText {
    if (correctAnswerText.isNotEmpty) return correctAnswerText;
    if (correctAnswer >= 0 && correctAnswer < choices.length) {
      return choices[correctAnswer];
    }
    return '';
  }

  String get resolvedCorrectAnswerTextRuby {
    if (correctAnswerTextRuby.isNotEmpty) return correctAnswerTextRuby;
    return resolvedCorrectAnswerText;
  }

  String get resolvedFormulaExplanation {
    if (formulaExplanation.isNotEmpty) return formulaExplanation;
    return [
      equationHint,
      thinkingHint,
    ].where((text) => text.isNotEmpty).join('\n');
  }

  String get resolvedFormulaExplanationRuby {
    if (formulaExplanationRuby.isNotEmpty) return formulaExplanationRuby;
    return resolvedFormulaExplanation;
  }

  String get resolvedLanguagePoint {
    if (languagePoint.isNotEmpty) return languagePoint;
    if (vocabulary.isNotEmpty) {
      return '大事な言葉: ${vocabulary.join('・')}';
    }
    return '問題文の最後を見て、何を答えるかを確かめましょう。';
  }

  String get resolvedLanguagePointRuby {
    if (languagePointRuby.isNotEmpty) return languagePointRuby;
    return resolvedLanguagePoint;
  }

  String explanationRubyFor(AppLanguage language) {
    if (language != AppLanguage.japanese) {
      return explanationFor(language);
    }
    if (explanationRuby.isNotEmpty) return explanationRuby;
    return explanationFor(language);
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

class VocabularyEntry {
  final String term;
  final List<String> surfaces;
  final String reading;
  final String simpleJapanese;
  final Map<AppLanguage, String> translations;
  final String exampleSentence;
  final String category;

  const VocabularyEntry({
    required this.term,
    this.surfaces = const [],
    required this.reading,
    required this.simpleJapanese,
    this.translations = const {},
    this.exampleSentence = '',
    this.category = '',
  });

  String translationFor(AppLanguage language) {
    return lookupNative(translations, language);
  }
}
