/*
[lesson.dart]

pur: 
*/

import 'question.dart';

enum LessonType { diagnosis, practice }

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
  });
}
