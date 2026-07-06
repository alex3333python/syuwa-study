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

  static List<Question> fractionComparisonProblems() {
    const values = [
      FractionComparisonTemplateValues(
        questionId: 5001,
        leftNumerator: 1,
        leftDenominator: 2,
        rightNumerator: 1,
        rightDenominator: 3,
      ),
      FractionComparisonTemplateValues(
        questionId: 5002,
        leftNumerator: 2,
        leftDenominator: 5,
        rightNumerator: 1,
        rightDenominator: 4,
      ),
      FractionComparisonTemplateValues(
        questionId: 5003,
        leftNumerator: 3,
        leftDenominator: 4,
        rightNumerator: 2,
        rightDenominator: 3,
      ),
    ];

    return values.map(fractionComparisonTemplate.build).toList();
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
