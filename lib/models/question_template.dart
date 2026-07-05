import 'app_language.dart';
import 'question.dart';

class QuestionTemplate {
  final String id;
  final String unitId;
  final List<String> tags;
  final Question Function(QuestionTemplateValues values) build;

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

const divisionWordProblemTemplate = QuestionTemplate(
  id: 'division_equal_share_1',
  unitId: 'division_word_problem',
  tags: ['division', 'word_problem', 'school_japanese_equally'],
  build: _buildDivisionWordProblem,
);

Question _buildDivisionWordProblem(QuestionTemplateValues values) {
  final wrong1 = values.answer + 1;
  final wrong2 = values.groups;
  final wrong3 = values.total - values.groups;

  return Question(
    id: values.questionId,
    type: 'multiple-choice',
    unitId: divisionWordProblemTemplate.unitId,
    promptSchoolJa:
        '${values.total}この${values.item}を、${values.groups}${values.people}で同じ数ずつ分けます。1${values.people}分は何こですか。',
    promptEasyJa:
        '${values.item}が${values.total}こあります。${values.groups}${values.people}で同じ数に分けます。ひとり何こですか。',
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
