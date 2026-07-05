import '../models/app_language.dart';
import '../models/question.dart';

const List<Question> diagnosticQuestions = [
  Question(
    id: 1001,
    type: 'multiple-choice',
    unitId: 'number_place_value',
    promptSchoolJa: '324は、百の位がいくつですか。',
    promptEasyJa: '324の「100がいくつあるところ」の数字はどれですか。',
    promptNative: {
      AppLanguage.portuguese:
          'Em 324, qual algarismo está na casa das centenas?',
      AppLanguage.tagalog: 'Sa 324, alin ang digit sa hundreds place?',
      AppLanguage.vietnamese: 'Trong số 324, chữ số hàng trăm là số nào?',
    },
    choices: ['2', '3', '4', '24'],
    correctAnswer: 1,
    explanationEasyJa: '324は、3百、2十、4です。百の位は3です。',
    explanationNative: {
      AppLanguage.portuguese: '324 tem 3 centenas, 2 dezenas e 4 unidades.',
      AppLanguage.tagalog: 'Ang 324 ay may 3 hundreds, 2 tens, at 4 ones.',
      AppLanguage.vietnamese: '324 gồm 3 trăm, 2 chục và 4 đơn vị.',
    },
    tags: ['place_value', 'math_concept'],
  ),
  Question(
    id: 1002,
    type: 'multiple-choice',
    unitId: 'addition_subtraction',
    promptSchoolJa: 'みかんが18こあります。7こ食べると、残りは何こですか。',
    promptEasyJa: 'みかんが18こあります。7こへります。あと何こありますか。',
    promptNative: {
      AppLanguage.portuguese:
          'Há 18 laranjas. Se 7 forem comidas, quantas sobram?',
      AppLanguage.tagalog:
          'May 18 dalandan. Kung kinain ang 7, ilan ang natira?',
      AppLanguage.vietnamese: 'Có 18 quả cam. Ăn 7 quả thì còn lại bao nhiêu?',
    },
    choices: ['7', '10', '11', '25'],
    correctAnswer: 2,
    explanationEasyJa: '「残り」は、ひき算の合図です。18 - 7 = 11です。',
    explanationNative: {
      AppLanguage.portuguese: '"Sobram" indica subtração. 18 - 7 = 11.',
      AppLanguage.tagalog:
          'Ang "natira" ay palatandaan ng subtraction. 18 - 7 = 11.',
      AppLanguage.vietnamese:
          '"Còn lại" là dấu hiệu của phép trừ. 18 - 7 = 11.',
    },
    tags: ['subtraction', 'word_problem', 'school_japanese_remaining'],
  ),
  Question(
    id: 1003,
    type: 'multiple-choice',
    unitId: 'multiplication',
    promptSchoolJa: '4人に、1人3まいずつカードを配ります。カードは全部で何まい必要ですか。',
    promptEasyJa: '4人います。ひとりに3まいカードをあげます。ぜんぶで何まいですか。',
    promptNative: {
      AppLanguage.portuguese:
          'Há 4 crianças. Cada uma recebe 3 cartões. Quantos cartões são necessários ao todo?',
      AppLanguage.tagalog:
          'May 4 na bata. Bawat isa ay bibigyan ng 3 card. Ilang card lahat?',
      AppLanguage.vietnamese:
          'Có 4 bạn. Mỗi bạn nhận 3 thẻ. Cần tất cả bao nhiêu thẻ?',
    },
    choices: ['7', '12', '16', '43'],
    correctAnswer: 1,
    explanationEasyJa: '「1人3まいずつ」が4人分なので、3 x 4 = 12です。',
    explanationNative: {
      AppLanguage.portuguese:
          'São 3 cartões para cada uma das 4 crianças: 3 x 4 = 12.',
      AppLanguage.tagalog:
          'May 3 card para sa bawat isa sa 4 na bata: 3 x 4 = 12.',
      AppLanguage.vietnamese: 'Mỗi bạn 3 thẻ, có 4 bạn: 3 x 4 = 12.',
    },
    tags: ['multiplication', 'word_problem', 'school_japanese_each'],
  ),
  Question(
    id: 1004,
    type: 'multiple-choice',
    unitId: 'division_word_problem',
    promptSchoolJa: '24このあめを、6人で同じ数ずつ分けます。1人分は何こですか。',
    promptEasyJa: 'あめが24こあります。6人で同じ数に分けます。ひとり何こですか。',
    promptNative: {
      AppLanguage.portuguese:
          '24 balas serão divididas igualmente entre 6 pessoas. Quantas para cada pessoa?',
      AppLanguage.tagalog:
          'Hahatiin nang pantay ang 24 kendi sa 6 na tao. Ilan ang para sa bawat isa?',
      AppLanguage.vietnamese:
          'Chia đều 24 cái kẹo cho 6 người. Mỗi người được bao nhiêu?',
    },
    choices: ['4', '6', '18', '30'],
    correctAnswer: 0,
    explanationEasyJa: '「同じ数ずつ分ける」は、わり算です。24 ÷ 6 = 4です。',
    explanationNative: {
      AppLanguage.portuguese:
          '"Dividir igualmente" indica divisão. 24 ÷ 6 = 4.',
      AppLanguage.tagalog: 'Ang "hatiin nang pantay" ay division. 24 ÷ 6 = 4.',
      AppLanguage.vietnamese: '"Chia đều" là phép chia. 24 ÷ 6 = 4.',
    },
    tags: ['division', 'word_problem', 'school_japanese_equally'],
  ),
  Question(
    id: 1005,
    type: 'multiple-choice',
    unitId: 'comparison',
    promptSchoolJa: 'Aは36cm、Bは29cmです。AはBより何cm長いですか。',
    promptEasyJa: 'Aは36cmです。Bは29cmです。Aのほうが何cm長いですか。',
    promptNative: {
      AppLanguage.portuguese:
          'A mede 36 cm e B mede 29 cm. Quantos cm A é mais longo que B?',
      AppLanguage.tagalog:
          'Ang A ay 36 cm at ang B ay 29 cm. Ilang cm ang mas mahaba ang A kaysa B?',
      AppLanguage.vietnamese:
          'A dài 36 cm, B dài 29 cm. A dài hơn B bao nhiêu cm?',
    },
    choices: ['5', '7', '9', '65'],
    correctAnswer: 1,
    explanationEasyJa: '「より何cm長い」は、ちがいを求めます。36 - 29 = 7です。',
    explanationNative: {
      AppLanguage.portuguese: 'A pergunta pede a diferença: 36 - 29 = 7.',
      AppLanguage.tagalog: 'Hinahanap ang diperensya: 36 - 29 = 7.',
      AppLanguage.vietnamese: 'Câu hỏi tìm hiệu: 36 - 29 = 7.',
    },
    tags: ['comparison', 'subtraction', 'school_japanese_more_than'],
  ),
];
