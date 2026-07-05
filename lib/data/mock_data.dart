import '../logic/question_generator.dart';
import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import 'diagnostic_questions.dart';

final List<Lesson> mockLessons = [
  const Lesson(
    id: 1,
    levelId: 1,
    type: LessonType.diagnosis,
    title: '算数チェック',
    description: '算数の考え方と、学校日本語のつまずきを分けて見ます。',
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
];
