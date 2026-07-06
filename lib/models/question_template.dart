import 'app_language.dart';
import 'question.dart';

class QuestionTemplate {
  final String id;
  final String unitId;
  final List<String> tags;
  final Question Function(dynamic values) build;

  const QuestionTemplate({
    required this.id,
    required this.unitId,
    required this.tags,
    required this.build,
  });
}

class QuestionTemplateValues {
  final int questionId;
  final int total;
  final int groups;
  final String item;
  final String people;

  const QuestionTemplateValues({
    required this.questionId,
    required this.total,
    required this.groups,
    required this.item,
    required this.people,
  });

  int get answer => total ~/ groups;
}

class FractionComparisonTemplateValues {
  final int questionId;
  final int leftNumerator;
  final int leftDenominator;
  final int rightNumerator;
  final int rightDenominator;

  const FractionComparisonTemplateValues({
    required this.questionId,
    required this.leftNumerator,
    required this.leftDenominator,
    required this.rightNumerator,
    required this.rightDenominator,
  });

  String get leftFraction => '$leftNumerator/$leftDenominator';
  String get rightFraction => '$rightNumerator/$rightDenominator';

  bool get isLeftGreater {
    return leftNumerator * rightDenominator > rightNumerator * leftDenominator;
  }

  String get correctFraction => isLeftGreater ? leftFraction : rightFraction;
}

const divisionWordProblemTemplate = QuestionTemplate(
  id: 'division_equal_share_1',
  unitId: 'division_word_problem',
  tags: ['division', 'word_problem', 'equal_share', 'school_japanese_equally'],
  build: _buildDivisionWordProblem,
);

Question _buildDivisionWordProblem(dynamic rawValues) {
  final values = rawValues as QuestionTemplateValues;
  final wrong1 = values.answer + 1;
  final wrong2 = values.groups;
  final wrong3 = values.total - values.groups;

  return Question(
    id: values.questionId,
    type: 'multiple-choice',
    unitId: divisionWordProblemTemplate.unitId,
    promptSchoolJa:
        '${values.total}この${values.item}を、${values.groups}${values.people}で等しく分けると、1${values.people}何こずつですか。',
    promptEasyJa:
        '${values.item}が${values.total}こあります。${values.groups}${values.people}で等しく分けると、ひとり何こずつですか。',
    promptNative: {
      AppLanguage.portuguese:
          'Divida ${values.total} ${values.item} igualmente entre ${values.groups} pessoas. Quantos para cada pessoa?',
      AppLanguage.tagalog:
          'Hatiin nang pantay ang ${values.total} ${values.item} sa ${values.groups} tao. Ilan ang bawat isa?',
      AppLanguage.vietnamese:
          'Chia đều ${values.total} ${values.item} cho ${values.groups} người. Mỗi người được bao nhiêu?',
    },
    choices: ['${values.answer}', '$wrong1', '$wrong2', '$wrong3'],
    correctAnswer: 0,
    explanationEasyJa:
        '同じ数ずつ分けるので、${values.total} ÷ ${values.groups} = ${values.answer}です。',
    explanationNative: {
      AppLanguage.portuguese:
          'Dividir igualmente usa divisão: ${values.total} ÷ ${values.groups} = ${values.answer}.',
      AppLanguage.tagalog:
          'Pantay na paghahati ay division: ${values.total} ÷ ${values.groups} = ${values.answer}.',
      AppLanguage.vietnamese:
          'Chia đều dùng phép chia: ${values.total} ÷ ${values.groups} = ${values.answer}.',
    },
    tags: divisionWordProblemTemplate.tags,
  );
}

const fractionComparisonTemplate = QuestionTemplate(
  id: 'fraction_comparison_1',
  unitId: 'fraction_comparison',
  tags: ['fraction', 'comparison'],
  build: _buildFractionComparison,
);

Question _buildFractionComparison(dynamic rawValues) {
  final values = rawValues as FractionComparisonTemplateValues;
  final leftChoice = values.leftFraction;
  final rightChoice = values.rightFraction;
  final sameChoice = '同じ大きさ';

  return Question(
    id: values.questionId,
    type: 'multiple-choice',
    unitId: fractionComparisonTemplate.unitId,
    promptSchoolJa:
        '${values.leftFraction} と ${values.rightFraction} は、どちらが大きいですか。',
    promptEasyJa:
        '${values.leftFraction} と ${values.rightFraction} をくらべます。大きいほうはどちらですか。',
    promptNative: {
      AppLanguage.portuguese:
          'Qual fração é maior: ${values.leftFraction} ou ${values.rightFraction}?',
      AppLanguage.tagalog:
          'Aling fraction ang mas malaki: ${values.leftFraction} o ${values.rightFraction}?',
      AppLanguage.vietnamese:
          'Phân số nào lớn hơn: ${values.leftFraction} hay ${values.rightFraction}?',
    },
    choices: [leftChoice, rightChoice, sameChoice],
    correctAnswer: values.isLeftGreater ? 0 : 1,
    explanationEasyJa:
        '分母がちがう分数は、同じ大きさの図を考えるとくらべやすいです。大きいのは ${values.correctFraction} です。',
    explanationNative: {
      AppLanguage.portuguese:
          'Para comparar frações, pense no mesmo todo dividido em partes. A maior é ${values.correctFraction}.',
      AppLanguage.tagalog:
          'Para ikumpara ang fractions, isipin ang parehong buo na hinati sa bahagi. Mas malaki ang ${values.correctFraction}.',
      AppLanguage.vietnamese:
          'Để so sánh phân số, hãy nghĩ về cùng một hình được chia thành các phần. Phân số lớn hơn là ${values.correctFraction}.',
    },
    tags: fractionComparisonTemplate.tags,
  );
}
