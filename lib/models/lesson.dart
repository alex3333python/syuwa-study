/*
[lesson.dart]

pur: 
*/

import 'question.dart';
import 'app_language.dart';

enum LessonType { diagnosis, practice }

enum LessonStepType { learn, guidedPractice, independentPractice, summary }

class LessonStep {
  final String id;
  final LessonStepType type;
  final String title;
  final String explanationSchoolJa;
  final String explanationEasyJa;
  final Map<AppLanguage, String> explanationNative;
  final List<Question> questions;

  const LessonStep({
    required this.id,
    required this.type,
    required this.title,
    this.explanationSchoolJa = '',
    this.explanationEasyJa = '',
    this.explanationNative = const {},
    this.questions = const [],
  });

  String explanationFor(AppLanguage language, QuestionPromptMode mode) {
    switch (mode) {
      case QuestionPromptMode.schoolJa:
        return explanationSchoolJa;
      case QuestionPromptMode.easyJa:
        return explanationEasyJa.isNotEmpty
            ? explanationEasyJa
            : explanationSchoolJa;
      case QuestionPromptMode.native:
        if (language == AppLanguage.japanese) {
          return explanationEasyJa.isNotEmpty
              ? explanationEasyJa
              : explanationSchoolJa;
        }
        return explanationNative[language] ??
            (explanationEasyJa.isNotEmpty
                ? explanationEasyJa
                : explanationSchoolJa);
    }
  }
}

class Lesson {
  final int id;
  final int levelId;
  final LessonType type;
  final String title;
  final String description;
  final bool completed;
  final bool locked;
  final int stars;
  final int maxStars;
  final List<Question> questions;
  final List<LessonStep> steps;

  const Lesson({
    required this.id,
    required this.levelId,
    this.type = LessonType.practice,
    required this.title,
    required this.description,
    required this.completed,
    required this.locked,
    required this.stars,
    required this.maxStars,
    required this.questions,
    this.steps = const [],
  });
}
