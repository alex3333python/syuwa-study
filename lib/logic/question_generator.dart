import '../models/question.dart';
import '../models/question_template.dart';

class QuestionGenerator {
  static List<Question> divisionWordProblems() {
    const values = [
      QuestionTemplateValues(
        questionId: 2001,
        total: 18,
        groups: 3,
        item: 'シール',
        people: '人',
      ),
      QuestionTemplateValues(
        questionId: 2002,
        total: 32,
        groups: 4,
        item: 'えんぴつ',
        people: '人',
      ),
      QuestionTemplateValues(
        questionId: 2003,
        total: 45,
        groups: 5,
        item: 'カード',
        people: '人',
      ),
    ];

    return values.map(divisionWordProblemTemplate.build).toList();
  }

  static List<Question> reviewQuestionsForTags(Set<String> tags) {
    final hasDivisionReviewTag =
        tags.contains('division') ||
        tags.contains('word_problem') ||
        tags.contains('equal_share') ||
        tags.contains('school_japanese_equally');

    if (!hasDivisionReviewTag) {
      return const [];
    }

    return divisionWordProblems();
  }
}
