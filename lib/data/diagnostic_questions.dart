import '../models/app_language.dart';
import '../models/question.dart';

/// 算数チェック用の診断問題。
/// 実装済み5単元（わり算 / あまりのあるわり算 / 時こくと時間 / 長さ / 重さ）を
/// 各2問、全体10問で確認する。
const List<Question> diagnosticQuestions = [
  // --- わり算 ---
  Question(
    id: 1001,
    type: 'multiple-choice',
    unitId: 'division',
    unit: 'わり算',
    promptSchoolJa: '12このあめを、3人で同じ数ずつ分けます。1人分は何こですか。',
    promptEasyJa: 'あめが12こあります。3人で同じ数に分けます。ひとり何こですか。',
    promptNative: {
      AppLanguage.portuguese:
          '12 balas serão divididas igualmente entre 3 pessoas. Quantas para cada pessoa?',
      AppLanguage.tagalog:
          'Hahatiin nang pantay ang 12 kendi sa 3 tao. Ilan ang para sa bawat isa?',
      AppLanguage.vietnamese:
          'Chia đều 12 cái kẹo cho 3 người. Mỗi người được bao nhiêu?',
    },
    choices: ['3', '4', '6', '9'],
    correctAnswer: 1,
    explanationEasyJa: '「同じ数ずつ分ける」は、わり算です。12 ÷ 3 = 4です。',
    explanationNative: {
      AppLanguage.portuguese:
          '"Dividir igualmente" indica divisão. 12 ÷ 3 = 4.',
      AppLanguage.tagalog: 'Ang "hatiin nang pantay" ay division. 12 ÷ 3 = 4.',
      AppLanguage.vietnamese: '"Chia đều" là phép chia. 12 ÷ 3 = 4.',
    },
    tags: [
      'division',
      'equal-sharing',
      'word_problem',
      'school_japanese_equally',
    ],
  ),
  Question(
    id: 1002,
    type: 'multiple-choice',
    unitId: 'division',
    unit: 'わり算',
    promptSchoolJa: '20このシールを、1人に5こずつ配ります。何人に配れますか。',
    promptEasyJa: 'シールが20こあります。1人に5こずつあげます。何人にあげられますか。',
    promptNative: {
      AppLanguage.portuguese:
          'Há 20 adesivos. Damos 5 para cada pessoa. Para quantas pessoas dá?',
      AppLanguage.tagalog:
          'May 20 sticker. Tig-5 ang ibibigay sa bawat tao. Ilan ang matuturuan?',
      AppLanguage.vietnamese:
          'Có 20 nhãn dán. Mỗi người được 5 cái. Phát được cho bao nhiêu người?',
    },
    choices: ['3人', '4人', '5人', '15人'],
    correctAnswer: 1,
    explanationEasyJa: '1人に5こずつなので、20 ÷ 5 = 4人です。',
    explanationNative: {
      AppLanguage.portuguese: 'Como são 5 por pessoa, 20 ÷ 5 = 4 pessoas.',
      AppLanguage.tagalog: 'Dahil tig-5 ang bawat isa, 20 ÷ 5 = 4 tao.',
      AppLanguage.vietnamese: 'Mỗi người 5 cái nên 20 ÷ 5 = 4 người.',
    },
    tags: [
      'division',
      'measurement-division',
      'word_problem',
      'school_japanese_each',
    ],
  ),

  // --- あまりのあるわり算 ---
  Question(
    id: 1003,
    type: 'multiple-choice',
    unitId: 'remainder',
    unit: 'あまりのあるわり算',
    promptSchoolJa: '14こを4こずつに分けると、何組できて、何こあまりますか。',
    promptEasyJa: '14こあります。4こずつのまとまりにします。何組と、あまりは何こですか。',
    promptNative: {
      AppLanguage.portuguese:
          'Separamos 14 em grupos de 4. Quantos grupos e quanto sobra?',
      AppLanguage.tagalog:
          'Hatiin ang 14 nang tig-4. Ilang grupo at ilan ang sobra?',
      AppLanguage.vietnamese:
          'Chia 14 thành từng nhóm 4. Được mấy nhóm và dư bao nhiêu?',
    },
    choices: ['3組あまり2こ', '2組あまり2こ', '3組あまり1こ', '4組あまり0こ'],
    correctAnswer: 0,
    explanationEasyJa: '4×3=12なので、3組できて、14-12=2こあまります。',
    explanationNative: {
      AppLanguage.portuguese: '4 × 3 = 12, então são 3 grupos e sobram 2.',
      AppLanguage.tagalog: '4 × 3 = 12, kaya 3 grupo at 2 ang sobra.',
      AppLanguage.vietnamese: '4 × 3 = 12 nên được 3 nhóm và dư 2.',
    },
    tags: ['remainder', 'division', 'remainder_calculation'],
  ),
  Question(
    id: 1004,
    type: 'multiple-choice',
    unitId: 'remainder',
    unit: 'あまりのあるわり算',
    promptSchoolJa: '子どもが17人います。1台に5人まで乗れます。車は何台必要ですか。',
    promptEasyJa: '子どもが17人います。1台に5人までです。あまりの人も乗るので、車は何台いりますか。',
    promptNative: {
      AppLanguage.portuguese:
          'Há 17 crianças. Cabem 5 por carro. Quantos carros são necessários?',
      AppLanguage.tagalog:
          'May 17 bata. 5 ang kasya sa isang kotse. Ilang kotse ang kailangan?',
      AppLanguage.vietnamese:
          'Có 17 trẻ. Mỗi xe chở tối đa 5 người. Cần bao nhiêu xe?',
    },
    choices: ['2台', '3台', '4台', '5台'],
    correctAnswer: 2,
    explanationEasyJa:
        '17 ÷ 5 = 3 あまり 2です。あまった2人も乗るので、車は4台必要です。',
    explanationNative: {
      AppLanguage.portuguese:
          '17 ÷ 5 = 3 resto 2. Como as 2 crianças restantes também precisam ir, são 4 carros.',
      AppLanguage.tagalog:
          '17 ÷ 5 = 3 sobra 2. Dahil sasakay din ang 2 natira, kailangan ng 4 kotse.',
      AppLanguage.vietnamese:
          '17 ÷ 5 = 3 dư 2. Vì 2 bạn còn lại cũng cần đi nên cần 4 xe.',
    },
    tags: [
      'remainder',
      'division',
      'word_problem',
      'round_up_context',
      'asked_meaning',
    ],
  ),

  // --- 時こくと時間 ---
  Question(
    id: 1005,
    type: 'multiple-choice',
    unitId: 'time',
    unit: '時こくと時間',
    promptSchoolJa: '7時40分に家を出て、8時10分に学校につきました。何分かかりましたか。',
    promptEasyJa: '7時40分に出ました。8時10分につきました。何分かかりましたか。',
    promptNative: {
      AppLanguage.portuguese:
          'Saiu de casa às 7:40 e chegou às 8:10. Quantos minutos demorou?',
      AppLanguage.tagalog:
          'Umalis nang 7:40 at dumating nang 8:10. Ilang minuto ang lumipas?',
      AppLanguage.vietnamese:
          'Ra khỏi nhà lúc 7:40 và đến lúc 8:10. Mất bao nhiêu phút?',
    },
    choices: ['20分', '30分', '40分', '50分'],
    correctAnswer: 1,
    explanationEasyJa:
        '7時40分から8時まで20分、8時から8時10分まで10分です。合わせて30分です。',
    explanationNative: {
      AppLanguage.portuguese:
          'De 7:40 até 8:00 são 20 minutos, e de 8:00 até 8:10 são 10. No total, 30 minutos.',
      AppLanguage.tagalog:
          'Mula 7:40 hanggang 8:00 ay 20 minuto, at mula 8:00 hanggang 8:10 ay 10. Kabuuan: 30 minuto.',
      AppLanguage.vietnamese:
          'Từ 7:40 đến 8:00 là 20 phút, từ 8:00 đến 8:10 là 10 phút. Tổng cộng 30 phút.',
    },
    tags: ['time', 'elapsed_time', 'word_problem'],
  ),
  Question(
    id: 1006,
    type: 'multiple-choice',
    unitId: 'time',
    unit: '時こくと時間',
    promptSchoolJa: '3時20分から40分後は、何時何分ですか。',
    promptEasyJa: 'いま3時20分です。40分すすめると、何時何分ですか。',
    promptNative: {
      AppLanguage.portuguese: 'São 3:20. Que horas serão daqui a 40 minutos?',
      AppLanguage.tagalog: 'Alas 3:20. Anong oras pagkalipas ng 40 minuto?',
      AppLanguage.vietnamese: 'Bây giờ là 3:20. 40 phút sau là mấy giờ?',
    },
    choices: ['3時50分', '3時60分', '4時0分', '4時20分'],
    correctAnswer: 2,
    explanationEasyJa:
        '3時20分から40分すすめると、3時60分になります。60分は1時間なので、4時0分です。',
    explanationNative: {
      AppLanguage.portuguese:
          '3:20 + 40 minutos = 4:00, porque 60 minutos formam 1 hora.',
      AppLanguage.tagalog:
          '3:20 + 40 minuto = 4:00, dahil 60 minuto ay 1 oras.',
      AppLanguage.vietnamese:
          '3:20 cộng 40 phút thành 4:00, vì 60 phút là 1 giờ.',
    },
    tags: ['time', 'minutes_after'],
  ),

  // --- 長さ ---
  Question(
    id: 1007,
    type: 'multiple-choice',
    unitId: 'length',
    unit: '長さ',
    promptSchoolJa: '1000mは何kmですか。',
    promptEasyJa: '1000メートルは、何キロメートルですか。',
    promptNative: {
      AppLanguage.portuguese: '1000 m são quantos km?',
      AppLanguage.tagalog: 'Ilang km ang 1000 m?',
      AppLanguage.vietnamese: '1000 m bằng bao nhiêu km?',
    },
    choices: ['1km', '10km', '100km', '1000km'],
    correctAnswer: 0,
    explanationEasyJa: '1000mと1kmは同じ長さです。',
    explanationNative: {
      AppLanguage.portuguese: '1000 m e 1 km são o mesmo comprimento.',
      AppLanguage.tagalog: 'Ang 1000 m at 1 km ay magkaparehong haba.',
      AppLanguage.vietnamese: '1000 m và 1 km là cùng một độ dài.',
    },
    tags: ['length', 'kilometer', 'unit'],
  ),
  Question(
    id: 1008,
    type: 'multiple-choice',
    unitId: 'length',
    unit: '長さ',
    promptSchoolJa: '1km200mは何mですか。',
    promptEasyJa: '1キロメートルと200メートルを合わせると、何メートルですか。',
    promptNative: {
      AppLanguage.portuguese: '1 km 200 m são quantos metros?',
      AppLanguage.tagalog: 'Ilang metro ang 1 km 200 m?',
      AppLanguage.vietnamese: '1 km 200 m bằng bao nhiêu mét?',
    },
    choices: ['200m', '1000m', '1200m', '3200m'],
    correctAnswer: 2,
    explanationEasyJa: '1kmは1000mです。1000mと200mを合わせると1200mです。',
    explanationNative: {
      AppLanguage.portuguese: '1 km = 1000 m. 1000 + 200 = 1200 m.',
      AppLanguage.tagalog: '1 km = 1000 m. 1000 + 200 = 1200 m.',
      AppLanguage.vietnamese: '1 km = 1000 m. 1000 + 200 = 1200 m.',
    },
    tags: ['length', 'kilometer', 'unit', 'word_problem'],
  ),

  // --- 重さ ---
  Question(
    id: 1009,
    type: 'multiple-choice',
    unitId: 'weight',
    unit: '重さ',
    promptSchoolJa: '1kgは何gですか。',
    promptEasyJa: '1キログラムは、何グラムですか。',
    promptNative: {
      AppLanguage.portuguese: '1 kg são quantos gramas?',
      AppLanguage.tagalog: 'Ilang gramo ang 1 kg?',
      AppLanguage.vietnamese: '1 kg bằng bao nhiêu gam?',
    },
    choices: ['10g', '100g', '1000g', '10000g'],
    correctAnswer: 2,
    explanationEasyJa: '1kgは1000gです。',
    explanationNative: {
      AppLanguage.portuguese: '1 kg = 1000 g.',
      AppLanguage.tagalog: '1 kg = 1000 g.',
      AppLanguage.vietnamese: '1 kg = 1000 g.',
    },
    tags: ['weight', 'kilogram', 'unit'],
  ),
  Question(
    id: 1010,
    type: 'multiple-choice',
    unitId: 'weight',
    unit: '重さ',
    promptSchoolJa: '1300gは、1kg何gですか。',
    promptEasyJa: '1300グラムは、1キログラムと何グラムですか。',
    promptNative: {
      AppLanguage.portuguese: '1300 g são 1 kg e quantos gramas?',
      AppLanguage.tagalog: 'Ang 1300 g ay 1 kg at ilang gramo?',
      AppLanguage.vietnamese: '1300 g bằng 1 kg và bao nhiêu gam?',
    },
    choices: ['1kg100g', '1kg300g', '1kg30g', '13kg'],
    correctAnswer: 1,
    explanationEasyJa: '1300gは、1000gと300gです。1000gは1kgなので、1kg300gです。',
    explanationNative: {
      AppLanguage.portuguese: '1300 g = 1000 g + 300 g = 1 kg 300 g.',
      AppLanguage.tagalog: '1300 g = 1000 g + 300 g = 1 kg 300 g.',
      AppLanguage.vietnamese: '1300 g = 1000 g + 300 g = 1 kg 300 g.',
    },
    tags: ['weight', 'gram', 'kilogram', 'unit'],
  ),
];
