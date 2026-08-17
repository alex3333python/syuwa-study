import '../logic/question_generator.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import 'diagnostic_questions.dart';
import 'grade3_division_unit.dart';
import 'grade3_division_remainder_unit.dart';
import 'grade3_length_unit.dart';
import 'grade3_time_unit.dart';
import 'grade3_weight_unit.dart';

final List<Lesson> _allMockLessons = [
  const Lesson(
    id: 1,
    levelId: 1,
    type: LessonType.diagnosis,
    title: '算数チェック',
    description: '',
    completed: false,
    locked: false,
    stars: 0,
    maxStars: 3,
    questions: diagnosticQuestions,
  ),
  Lesson(
    id: 2,
    levelId: 1,
    type: LessonType.practice,
    title: 'わり算の文章題',
    description: '「同じ数ずつ分ける」を使って、わり算の文章題を練習します。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: QuestionGenerator.divisionWordProblems(),
  ),
  const Lesson(
    id: 3,
    levelId: 1,
    type: LessonType.practice,
    title: 'かけ算の文章題',
    description: '「1人に3まいずつ」などの言葉から、かけ算を選ぶ練習です。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: [
      Question(
        id: 3001,
        type: 'multiple-choice',
        unitId: 'multiplication',
        promptSchoolJa: '5人に、1人4まいずつ紙を配ります。紙は全部で何まい必要ですか。',
        promptEasyJa: '5人います。ひとりに4まい紙をあげます。ぜんぶで何まいですか。',
        promptNative: {
          AppLanguage.portuguese:
              'Há 5 crianças. Cada uma recebe 4 folhas. Quantas folhas ao todo?',
          AppLanguage.tagalog:
              'May 5 na bata. Bawat isa ay bibigyan ng 4 na papel. Ilang papel lahat?',
          AppLanguage.vietnamese:
              'Có 5 bạn. Mỗi bạn nhận 4 tờ giấy. Tất cả là bao nhiêu tờ?',
        },
        choices: ['9', '20', '45', '54'],
        correctAnswer: 1,
        explanationEasyJa: '4まいが5人分なので、4 x 5 = 20です。',
        explanationNative: {
          AppLanguage.portuguese:
              'São 4 folhas para cada uma das 5 crianças: 4 x 5 = 20.',
          AppLanguage.tagalog: '4 na papel para sa 5 bata: 4 x 5 = 20.',
          AppLanguage.vietnamese: 'Mỗi bạn 4 tờ, có 5 bạn: 4 x 5 = 20.',
        },
        tags: ['multiplication', 'word_problem', 'school_japanese_each'],
      ),
    ],
  ),
  const Lesson(
    id: 4,
    levelId: 1,
    type: LessonType.practice,
    title: 'ちがいを求める問題',
    description: '「より長い」「残り」など、ひき算につながる言葉を確認します。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: [
      Question(
        id: 4001,
        type: 'multiple-choice',
        unitId: 'comparison',
        promptSchoolJa: '赤いリボンは42cm、青いリボンは35cmです。赤は青より何cm長いですか。',
        promptEasyJa: '赤は42cmです。青は35cmです。赤のほうが何cm長いですか。',
        promptNative: {
          AppLanguage.portuguese:
              'A fita vermelha tem 42 cm e a azul tem 35 cm. Quantos cm a vermelha é mais longa?',
          AppLanguage.tagalog:
              'Ang pulang laso ay 42 cm at ang asul ay 35 cm. Ilang cm ang mas mahaba ang pula?',
          AppLanguage.vietnamese:
              'Ruy băng đỏ dài 42 cm, ruy băng xanh dài 35 cm. Đỏ dài hơn bao nhiêu cm?',
        },
        choices: ['7', '13', '77', '87'],
        correctAnswer: 0,
        explanationEasyJa: '「より何cm長い」は、ちがいを求めます。42 - 35 = 7です。',
        explanationNative: {
          AppLanguage.portuguese: 'A pergunta pede a diferença: 42 - 35 = 7.',
          AppLanguage.tagalog: 'Hinahanap ang diperensya: 42 - 35 = 7.',
          AppLanguage.vietnamese: 'Câu hỏi tìm hiệu: 42 - 35 = 7.',
        },
        tags: ['comparison', 'subtraction', 'school_japanese_more_than'],
      ),
    ],
  ),
  Lesson(
    id: 5,
    levelId: 1,
    type: LessonType.practice,
    title: '分数の大きさ',
    description: '1/2 と 1/3 など、分数の大きさをくらべる練習です。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: QuestionGenerator.fractionComparisonProblems(),
  ),
  const Lesson(
    id: 6,
    levelId: 1,
    type: LessonType.practice,
    title: '残りはいくつ',
    description: '「残り」「食べる」「使う」などの言葉から、ひき算で考える練習をします。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: [],
    steps: [
      LessonStep(
        id: 'remaining-learn',
        type: LessonStepType.learn,
        title: '学習しよう',
        explanationSchoolJa:
            'ひき算は、数がへるときや残りを求めるときに使います。「残りは何こですか」は、はじめの数から使った数をひく合図です。',
        explanationEasyJa: 'ものがへったときは、ひき算を使います。「残り」は、まだある数のことです。',
        explanationNative: {
          AppLanguage.portuguese:
              'Use subtração quando a quantidade diminui. "Restam" quer dizer a quantidade que ainda fica.',
          AppLanguage.tagalog:
              'Gumamit ng pagbabawas kapag nabawasan ang bilang. Ang "natira" ay bilang na naiwan.',
          AppLanguage.vietnamese:
              'Dùng phép trừ khi số lượng giảm. "Còn lại" là số vẫn còn.',
        },
      ),
      LessonStep(
        id: 'remaining-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに解こう',
        questions: [
          Question(
            id: 6001,
            type: 'wordProblem',
            unitId: 'subtraction_remaining',
            promptSchoolJa: 'りんごが12こあります。4こ食べると、残りは何こですか。',
            promptEasyJa: 'りんごが12こあります。4こ食べました。まだあるりんごは何こですか。',
            promptNative: {
              AppLanguage.portuguese:
                  'Há 12 maçãs. Comeram 4. Quantas maçãs restam?',
              AppLanguage.tagalog:
                  'May 12 mansanas. Kinain ang 4. Ilang mansanas ang natira?',
              AppLanguage.vietnamese:
                  'Có 12 quả táo. Đã ăn 4 quả. Còn lại bao nhiêu quả táo?',
            },
            choices: ['4', '8', '12', '16'],
            correctAnswer: 1,
            explanationEasyJa: '12こから4こへったので、12 - 4 = 8です。',
            explanationNative: {
              AppLanguage.portuguese: 'Diminuiu 4 a partir de 12: 12 - 4 = 8.',
              AppLanguage.tagalog: 'Nabawasan ng 4 mula sa 12: 12 - 4 = 8.',
              AppLanguage.vietnamese: 'Bớt 4 từ 12: 12 - 4 = 8.',
            },
            tags: ['subtraction', 'word_problem', 'remaining'],
          ),
        ],
      ),
      LessonStep(
        id: 'remaining-independent',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          Question(
            id: 6002,
            type: 'wordProblem',
            unitId: 'subtraction_remaining',
            promptSchoolJa: '色紙が15まいあります。6まい使うと、残りは何まいですか。',
            promptEasyJa: '色紙が15まいあります。6まい使いました。まだある色紙は何まいですか。',
            promptNative: {
              AppLanguage.portuguese:
                  'Há 15 folhas de papel colorido. Usaram 6. Quantas folhas restam?',
              AppLanguage.tagalog:
                  'May 15 pirasong papel. Ginamit ang 6. Ilang papel ang natira?',
              AppLanguage.vietnamese:
                  'Có 15 tờ giấy màu. Đã dùng 6 tờ. Còn lại bao nhiêu tờ?',
            },
            choices: ['6', '9', '15', '21'],
            correctAnswer: 1,
            explanationEasyJa: '15まいから6まいへったので、15 - 6 = 9です。',
            explanationNative: {
              AppLanguage.portuguese: 'Diminuiu 6 a partir de 15: 15 - 6 = 9.',
              AppLanguage.tagalog: 'Nabawasan ng 6 mula sa 15: 15 - 6 = 9.',
              AppLanguage.vietnamese: 'Bớt 6 từ 15: 15 - 6 = 9.',
            },
            tags: ['subtraction', 'word_problem', 'remaining'],
          ),
        ],
      ),
      LessonStep(
        id: 'remaining-summary',
        type: LessonStepType.summary,
        title: 'まとめ',
        explanationSchoolJa:
            '「残り」「食べる」「使う」「なくなる」は、数がへる合図です。はじめの数からへった数をひくと、残りが分かります。',
        explanationEasyJa: '「残り」「食べる」「使う」「なくなる」が出たら、ひき算で考えます。',
        explanationNative: {
          AppLanguage.portuguese:
              'Quando aparecerem palavras como restam, comer, usar ou acabar, pense em subtração.',
          AppLanguage.tagalog:
              'Kapag may salitang natira, kumain, gumamit, o naubos, isipin ang pagbabawas.',
          AppLanguage.vietnamese:
              'Khi thấy các từ còn lại, ăn, dùng, hết, hãy nghĩ đến phép trừ.',
        },
      ),
    ],
  ),
  ...grade3DivisionLessons,
  ...grade3DivisionRemainderLessons,
  ...grade3TimeLessons,
  ...grade3LengthLessons,
  ...grade3WeightLessons,
];

const Set<int> _hiddenLessonIds = {2, 3, 4, 5, 6, 10, 13, 14};

final List<Lesson> mockLessons = _allMockLessons
    .where((lesson) => !_hiddenLessonIds.contains(lesson.id))
    .toList();
