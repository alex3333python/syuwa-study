import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';

final List<Lesson> grade3LengthLessons = [
  Lesson(
    id: 21,
    levelId: 3,
    type: LessonType.practice,
    title: '長さのはかり方',
    description: 'ものさしとまきじゃくを使い分けて、長さをはかります。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'length-measure-learn',
        title: '学習しよう',
        school: 'はかるものに合わせて、道具を選びます。',
        easy: 'ものさしとまきじゃくを使って、長さをはかります。',
        native: {
          AppLanguage.portuguese:
              'Vamos escolher a ferramenta certa para medir cada objeto.',
        },
      ),
      _learn(
        id: 'length-measure-words',
        title: 'ことばを知ろう',
        school: '長さをはかるときに使うことばを確認します。',
        easy: '長さの言葉です。',
      ),
      LessonStep(
        id: 'length-measure-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに考えよう',
        questions: [
          _q(
            id: 21101,
            type: 'tool_choice',
            school: 'つくえのよこの長さをはかります。どの道具を使うとよいですか。',
            easy: 'つくえは、ものさしではかれそうな長さです。',
            native: {
              AppLanguage.portuguese:
                  'Vamos medir a largura da mesa. Qual ferramenta é melhor usar?',
            },
            questionTextRuby:
                'つくえのよこの{長さ|ながさ}を{はかります|はかります}。どの{道具|どうぐ}を{使|つか}うとよいですか。',
            choices: ['ものさし', 'まきじゃく', '地図'],
            correct: 0,
            explanation: 'つくえのような短いものは、ものさしではかりやすいです。0の目もりをはしに合わせます。',
            explanationRuby:
                'つくえのような{短|みじか}いものは、ものさしで{はかり|はかり}やすいです。0の{目もり|めもり}をはしに{合|あ}わせます。',
            tags: ['length', 'ruler', 'tool_choice'],
            diagramType: 'length_bar',
            diagramData: const {
              'label': 'つくえ',
              'value': '70cm',
              'ticks': '0|10|20|30|40|50|60|70',
            },
          ),
          _q(
            id: 21102,
            type: 'tape_measure',
            school: '教室のよこの長さをはかります。どの道具を使うとよいですか。',
            easy: '長いものをはかる道具を考えます。',
            native: {
              AppLanguage.portuguese:
                  'Vamos medir a largura da sala. Qual ferramenta é melhor usar?',
            },
            questionTextRuby:
                '{教室|きょうしつ}のよこの{長さ|ながさ}を{はかります|はかります}。どの{道具|どうぐ}を{使|つか}うとよいですか。',
            choices: ['ものさし', 'まきじゃく', '時計'],
            correct: 1,
            explanation: '教室のように長いものは、まきじゃくを使うとはかりやすいです。',
            explanationRuby:
                '{教室|きょうしつ}のように{長|なが}いものは、まきじゃくを{使|つか}うと{はかり|はかり}やすいです。',
            tags: ['length', 'tape_measure', 'tool_choice'],
            diagramType: 'length_bar',
            diagramData: const {
              'label': '教室のよこ',
              'value': '6m',
              'ticks': '0|1|2|3|4|5|6',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'length-measure-practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 21103,
            type: 'read_measure',
            school: 'まきじゃくが4mを指しています。長さはどれですか。',
            easy: 'まきじゃくの目もりを読みます。',
            questionTextRuby: 'まきじゃくが4mを{指|さ}しています。{長さ|ながさ}はどれですか。',
            choices: ['3m', '4m', '40m'],
            correct: 1,
            explanation: 'まきじゃくの目もりが4mのところを指しているので、長さは4mです。',
            explanationRuby:
                'まきじゃくの{目もり|めもり}が4mのところを{指|さ}しているので、{長さ|ながさ}は4mです。',
            tags: ['length', 'read_scale'],
            diagramType: 'length_bar',
            diagramData: const {
              'label': 'まきじゃく',
              'value': '4m',
              'ticks': '0|1|2|3|4|5',
            },
          ),
          _q(
            id: 21104,
            type: 'tool_choice',
            school: '木のみきのまわりをはかります。どの道具を使うとよいですか。',
            easy: '曲がったところにそわせやすい道具を選びます。',
            questionTextRuby:
                '{木|き}のみきのまわりを{はかります|はかります}。どの{道具|どうぐ}を{使|つか}うとよいですか。',
            choices: ['ものさし', 'まきじゃく', '時計'],
            correct: 1,
            explanation: 'まきじゃくは、曲がったところにそわせてはかることもできます。',
            explanationRuby: 'まきじゃくは、{曲|ま}がったところにそわせて{はかる|はかる}こともできます。',
            tags: ['length', 'tape_measure', 'curved'],
          ),
        ],
      ),
      LessonStep(
        id: 'length-measure-japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 21105,
            type: 'tool_choice',
            school: 'えんぴつの長さをはかります。どの道具を使うとよいですか。',
            easy: '短いものをはかります。',
            choices: ['ものさし', 'まきじゃく', '地図'],
            correct: 0,
            explanation: 'えんぴつのような短いものは、ものさしではかりやすいです。',
            tags: ['length', 'ruler', 'tool_choice'],
          ),
        ],
      ),
    ],
  ),
  Lesson(
    id: 22,
    levelId: 3,
    type: LessonType.practice,
    title: 'キロメートル',
    description: '地図の道のりから、kmとmの関係を考えます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'length-km-learn',
        title: '学習しよう',
        school: '町の中の道のりを見て、kmを使うよさを考えます。',
        easy: '長い道のりを、kmで表します。',
        native: {
          AppLanguage.portuguese:
              'Vamos usar quilômetros para mostrar caminhos longos na cidade.',
        },
      ),
      _learn(
        id: 'length-km-words',
        title: 'ことばを知ろう',
        school: 'kmや道のりのことばを確認します。',
        easy: '長い長さの言葉です。',
      ),
      LessonStep(
        id: 'length-km-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに考えよう',
        questions: [
          _q(
            id: 22101,
            type: 'km_relation',
            school: '1000mは何kmですか。',
            easy: '1000mと1kmは同じ長さです。',
            native: {AppLanguage.portuguese: '1000 m são quantos km?'},
            questionTextRuby: '1000mは{何|なん}kmですか。',
            choices: ['1km', '10km', '100km'],
            correct: 0,
            explanation: '1000mと1kmは同じ長さです。',
            explanationRuby: '1000mと1kmは{同|おな}じ{長さ|ながさ}です。',
            tags: ['length', 'kilometer', 'conversion'],
            diagramType: 'distance_map',
            diagramData: const {
              'places': '学校|交差点|コンビニ|公園',
              'segments': '300m|400m|300m',
              'caption': '300m + 400m + 300m = 1000m = 1km',
            },
          ),
          _q(
            id: 22102,
            type: 'km_to_m',
            school: '1km200mは何mですか。',
            easy: '1kmを1000mに直して考えます。',
            native: {
              AppLanguage.portuguese: '1 km e 200 m são quantos metros?',
            },
            questionTextRuby: '1km200mは{何|なん}mですか。',
            choices: ['1020m', '1200m', '2000m'],
            correct: 1,
            explanation: '1kmは1000mです。1000mと200mを合わせると1200mです。',
            explanationRuby: '1kmは1000mです。1000mと200mを{合|あ}わせると1200mです。',
            tags: ['length', 'kilometer', 'conversion'],
            diagramType: 'length_bar',
            diagramData: const {
              'label': '1km200m',
              'value': '1200m',
              'ticks': '0|200|400|600|800|1000|1200',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'length-km-practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 22103,
            type: 'compare_length',
            school: '900mと1km100mでは、どちらが長いですか。',
            easy: 'kmをmに直して比べます。',
            questionTextRuby: '900mと1km100mでは、どちらが{長|なが}いですか。',
            choices: ['900m', '1km100m', '同じ'],
            correct: 1,
            explanation: '1km100mは1100mです。1100mは900mより長いです。',
            explanationRuby: '1km100mは1100mです。1100mは900mより{長|なが}いです。',
            tags: ['length', 'kilometer', 'compare'],
          ),
          _q(
            id: 22104,
            type: 'route_addition',
            school: '学校から公園まで800m、公園から図書館まで600mです。全部で何mですか。',
            easy: '道のりをつなげて考えます。',
            questionTextRuby:
                '{学校|がっこう}から{公園|こうえん}まで800m、{公園|こうえん}から{図書館|としょかん}まで600mです。{全部|ぜんぶ}で{何|なん}mですか。',
            choices: ['1200m', '1400m', '1km600m'],
            correct: 1,
            explanation: '800mと600mを合わせると1400mです。1400mは1km400mとも表せます。',
            explanationRuby:
                '800mと600mを{合|あ}わせると1400mです。1400mは1km400mとも{表|あらわ}せます。',
            tags: ['length', 'kilometer', 'route_addition'],
            diagramType: 'distance_map',
            diagramData: const {
              'places': '学校|公園|図書館',
              'segments': '800m|600m',
              'caption': '800m + 600m = 1400m',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'length-km-japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 22105,
            type: 'm_to_km',
            school: '1600mは、1km何mですか。',
            easy: '1000mを1kmにします。',
            choices: ['1km60m', '1km600m', '16km'],
            correct: 1,
            explanation: '1600mは、1000mと600mです。1000mは1kmなので、1km600mです。',
            tags: ['length', 'kilometer', 'conversion'],
          ),
        ],
      ),
    ],
  ),
];

LessonStep _learn({
  required String id,
  required String title,
  required String school,
  required String easy,
  Map<AppLanguage, String> native = const {},
}) {
  return LessonStep(
    id: id,
    type: LessonStepType.learn,
    title: title,
    explanationSchoolJa: school,
    explanationEasyJa: easy,
    explanationNative: native,
  );
}

Question _q({
  required int id,
  required String type,
  required String school,
  required String easy,
  required List<String> choices,
  required int correct,
  required String explanation,
  required List<String> tags,
  Map<AppLanguage, String> native = const {},
  String questionTextRuby = '',
  String explanationRuby = '',
  String diagramType = '',
  Map<String, String> diagramData = const {},
}) {
  return Question(
    id: id,
    type: type,
    unitId: 'grade3_length',
    promptSchoolJa: school,
    promptEasyJa: easy,
    promptNative: native,
    questionTextRuby: questionTextRuby,
    choices: choices,
    correctAnswer: correct,
    correctAnswerText: choices[correct],
    explanationEasyJa: explanation,
    explanation: explanation,
    explanationRuby: explanationRuby,
    explanationNative: _lengthExplanationNative(id),
    tags: ['grade3', 'math', 'length', ...tags],
    diagramType: diagramType,
    diagramData: diagramData,
    grade: 3,
    subject: 'math',
    unit: 'length',
  );
}

Map<AppLanguage, String> _lengthExplanationNative(int id) {
  final portuguese = switch (id) {
    21101 =>
      'Para objetos curtos, como uma mesa, é fácil medir com uma régua. Alinhe o 0 da régua com a ponta.',
    21102 =>
      'Para objetos longos, como a sala de aula, é mais fácil medir com uma fita métrica.',
    21103 => 'A marca da fita está em 4 m, então o comprimento é 4 m.',
    21104 =>
      'A fita métrica também pode acompanhar partes curvas para medir ao redor.',
    21105 => 'Para objetos curtos, como um lápis, é fácil medir com uma régua.',
    22101 => '1000 m e 1 km têm o mesmo comprimento.',
    22102 => '1 km são 1000 m. 1000 m mais 200 m são 1200 m.',
    22103 => '1 km e 100 m são 1100 m. 1100 m é maior que 900 m.',
    22104 =>
      '800 m mais 600 m são 1400 m. Também podemos escrever 1400 m como 1 km e 400 m.',
    22105 =>
      '1600 m são 1000 m mais 600 m. 1000 m são 1 km, então é 1 km e 600 m.',
    _ => '',
  };
  if (portuguese.isEmpty) return const {};
  return {AppLanguage.portuguese: portuguese};
}
