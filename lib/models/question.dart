import 'app_language.dart';

class Question {
  final int id;
  final String type;
  final String unitId;
  final String promptSchoolJa;
  final String promptEasyJa;
  final Map<AppLanguage, String> promptNative;
  final List<String> choices;
  final String explanationEasyJa;
  final Map<AppLanguage, String> explanationNative;
  final List<String> tags;
  final String equationHint;
  final String thinkingHint;
  final String visualHint;
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
    this.explanationEasyJa = '',
    this.explanationNative = const {},
    this.tags = const [],
    this.equationHint = '',
    this.thinkingHint = '',
    this.visualHint = '',
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
    if (language == AppLanguage.japanese) {
      return explanationEasyJa;
    }
    return explanationNative[language] ?? explanationEasyJa;
  }
}

enum QuestionPromptMode { schoolJa, easyJa, native }
