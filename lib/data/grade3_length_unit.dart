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
          AppLanguage.tagalog:
              'Pumili tayo ng tamang gamit para sukatin ang bawat bagay.',
          AppLanguage.vietnamese:
              'Hãy chọn dụng cụ phù hợp để đo từng đồ vật.',
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
              AppLanguage.tagalog:
                  'Sukatin natin ang lapad ng mesa. Aling gamit ang mas maganda?',
              AppLanguage.vietnamese:
                  'Hãy đo chiều ngang cái bàn. Dùng dụng cụ nào thì tốt?',
            },
            questionTextRuby:
                'つくえのよこの{長|なが}さをはかります。どの{道具|どうぐ}を{使|つか}うとよいですか。',
            choices: ['ものさし', 'まきじゃく', '地図'],
            correct: 0,
            explanation: 'つくえのような短いものは、ものさしではかりやすいです。0の目もりをはしに合わせます。',
            explanationRuby:
                'つくえのような{短|みじか}いものは、ものさしではかりやすいです。0の{目|め}もりをはしに{合|あ}わせます。',
            tags: ['length', 'ruler', 'tool_choice'],
          ),
          _q(
            id: 21102,
            type: 'tape_measure',
            school: '教室のよこの長さをはかります。どの道具を使うとよいですか。',
            easy: '長いものをはかる道具を考えます。',
            native: {
              AppLanguage.portuguese:
                  'Vamos medir a largura da sala. Qual ferramenta é melhor usar?',
              AppLanguage.tagalog:
                  'Sukatin natin ang lapad ng silid. Aling gamit ang mas maganda?',
              AppLanguage.vietnamese:
                  'Hãy đo chiều ngang phòng học. Dùng dụng cụ nào thì tốt?',
            },
            questionTextRuby:
                '{教室|きょうしつ}のよこの{長|なが}さをはかります。どの{道具|どうぐ}を{使|つか}うとよいですか。',
            choices: ['ものさし', 'まきじゃく', '時計'],
            correct: 1,
            explanation: '教室のように長いものは、まきじゃくを使うとはかりやすいです。',
            explanationRuby:
                '{教室|きょうしつ}のように{長|なが}いものは、まきじゃくを{使|つか}うとはかりやすいです。',
            tags: ['length', 'tape_measure', 'tool_choice'],
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
            school: '消しゴムの長さをものさしではかります。長さはどれくらいですか。',
            easy: 'ものさしの目もりを見て、消しゴムの長さを読みます。',
            native: {
              AppLanguage.portuguese:
                  'Medimos o comprimento da borracha com uma régua. Qual é o comprimento?',
              AppLanguage.tagalog:
                  'Sinasukat ang haba ng pambura gamit ang ruler. Magkano ang haba?',
              AppLanguage.vietnamese:
                  'Đo chiều dài cục tẩy bằng thước kẻ. Dài bao nhiêu?',
            },
            questionTextRuby:
                '{消|け}しゴムの{長|なが}さをものさしではかります。{長|なが}さはどれくらいですか。',
            choices: ['3cm', '4cm', '5cm'],
            correct: 1,
            explanation: '消しゴムの左はしを0に合わせると、右はしが4cmの目もりにあります。',
            explanationRuby:
                '{消|け}しゴムの{左|ひだり}はしを0に{合|あ}わせると、{右|みぎ}はしが4cmの{目|め}もりにあります。',
            tags: ['length', 'ruler', 'read_scale'],
            diagramType: 'eraser_ruler',
            diagramData: const {
              'object': 'eraser',
              'lengthCm': '4',
              'showInExplanation': 'false',
            },
          ),
          _q(
            id: 21104,
            type: 'tool_choice',
            school: '木のみきのまわりをはかります。どの道具を使うとよいですか。',
            easy: '曲がったところにそわせやすい道具を選びます。',
            native: {
              AppLanguage.portuguese: 'Vamos medir ao redor do tronco. Qual ferramenta é melhor usar?',
              AppLanguage.tagalog: 'Sukatin natin ang paligid ng puno. Aling gamit ang mas maganda?',
              AppLanguage.vietnamese: 'Hãy đo vòng quanh thân cây. Dùng dụng cụ nào thì tốt?',
            },
            questionTextRuby:
                '{木|き}のみきのまわりをはかります。どの{道具|どうぐ}を{使|つか}うとよいですか。',
            choices: ['ものさし', 'まきじゃく', '時計'],
            correct: 1,
            explanation: 'まきじゃくは、曲がったところにそわせてはかることもできます。',
            explanationRuby: 'まきじゃくは、{曲|ま}がったところにそわせてはかることもできます。',
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
          AppLanguage.tagalog:
              'Gagamit tayo ng kilometro para ipakita ang mahahabang daan sa bayan.',
          AppLanguage.vietnamese:
              'Hãy dùng kilômét để thể hiện đường dài trong thành phố.',
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
            native: {
              AppLanguage.portuguese: '1000 m são quantos km?',
              AppLanguage.tagalog: 'Ilang km ang 1000 m?',
              AppLanguage.vietnamese: '1000 m bằng bao nhiêu km?',
            },
            questionTextRuby: '1000mは{何|なん}kmですか。',
            choices: ['1km', '10km', '100km'],
            correct: 0,
            explanation: '1000mと1kmは同じ長さです。',
            explanationRuby: '1000mと1kmは{同|おな}じ{長さ|ながさ}です。',
            tags: ['length', 'kilometer', 'conversion'],
          ),
          _q(
            id: 22102,
            type: 'km_to_m',
            school: '1km200mは何mですか。',
            easy: '1kmを1000mに直して考えます。',
            native: {
              AppLanguage.portuguese: '1 km e 200 m são quantos metros?',
              AppLanguage.tagalog: 'Ilang metro ang 1 km at 200 m?',
              AppLanguage.vietnamese: '1 km và 200 m bằng bao nhiêu mét?',
            },
            questionTextRuby: '1km200mは{何|なん}mですか。',
            choices: ['1020m', '1200m', '2000m'],
            correct: 1,
            explanation: '1kmは1000mです。1000mと200mを合わせると1200mです。',
            explanationRuby: '1kmは1000mです。1000mと200mを{合|あ}わせると1200mです。',
            tags: ['length', 'kilometer', 'conversion'],
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
            native: {
              AppLanguage.portuguese: 'Qual é mais longo: 900 m ou 1 km e 100 m?',
              AppLanguage.tagalog: 'Alin ang mas mahaba: 900 m o 1 km at 100 m?',
              AppLanguage.vietnamese: 'Cái nào dài hơn: 900 m hay 1 km 100 m?',
            },
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
            native: {
              AppLanguage.portuguese: 'Da escola ao parque são 800 m, e do parque à biblioteca 600 m. Quantos metros ao todo?',
              AppLanguage.tagalog: '800 m mula paaralan hanggang parke, at 600 m mula parke hanggang aklatan. Ilang metro lahat?',
              AppLanguage.vietnamese: 'Từ trường đến công viên 800 m, từ công viên đến thư viện 600 m. Tổng cộng bao nhiêu mét?',
            },
            questionTextRuby:
                '{学校|がっこう}から{公園|こうえん}まで800m、{公園|こうえん}から{図書館|としょかん}まで600mです。{全部|ぜんぶ}で{何|なん}mですか。',
            choices: ['1200m', '1400m', '1km600m'],
            correct: 1,
            explanation: '800mと600mを合わせると1400mです。1400mは1km400mとも表せます。',
            explanationRuby:
                '800mと600mを{合|あ}わせると1400mです。1400mは1km400mとも{表|あらわ}せます。',
            tags: ['length', 'kilometer', 'route_addition'],
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
  Lesson(
    id: 25,
    levelId: 3,
    title: 'たしかめ問題',
    description: '',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      LessonStep(
        id: 'length-check',
        type: LessonStepType.independentPractice,
        title: 'たしかめ問題',
        questions: [
          _q(
            id: 25101,
            type: 'read_measure',
            school: '消しゴムの長さをものさしではかります。長さは何cmですか。',
            easy: 'ものさしの目もりを読みます。',
            native: {
              AppLanguage.portuguese: 'Medimos o comprimento da borracha com uma régua. Quantos cm são?',
              AppLanguage.tagalog: 'Sinasukat ang haba ng pambura gamit ang ruler. Ilang cm?',
              AppLanguage.vietnamese: 'Đo chiều dài cục tẩy bằng thước kẻ. Bao nhiêu cm?',
            },
            choices: ['3cm', '4cm', '5cm'],
            correct: 1,
            explanation: '消しゴムの左はしを0に合わせると、右はしが4cmの目もりにあります。',
            explanationRuby:
                '{消|け}しゴムの{左|ひだり}はしを0に{合|あ}わせると、{右|みぎ}はしが4cmの{目|め}もりにあります。',
            diagramType: 'eraser_ruler',
            diagramData: const {
              'object': 'eraser',
              'lengthCm': '4',
              'showInExplanation': 'false',
            },
            tags: ['check', 'ruler', 'read_scale'],
          ),
          _q(
            id: 25102,
            type: 'tool_choice',
            school: 'ろうかの長さをはかるとき、どの道具を使いますか。',
            easy: '長いものをはかる道具を選びます。',
            native: {
              AppLanguage.portuguese: 'Para medir o comprimento do corredor, qual ferramenta usamos?',
              AppLanguage.tagalog: 'Para sukatin ang haba ng pasilyo, aling gamit ang gagamitin?',
              AppLanguage.vietnamese: 'Khi đo chiều dài hành lang, dùng dụng cụ nào?',
            },
            choices: ['ものさし', 'まきじゃく', '時計'],
            correct: 1,
            explanation: 'ろうかのように長いものは、まきじゃくを使うとはかりやすいです。',
            explanationRuby:
                'ろうかのように{長|なが}いものは、まきじゃくを{使|つか}うとはかりやすいです。',
            tags: ['check', 'tool', 'tape_measure'],
          ),
          _q(
            id: 25103,
            type: 'km_relation',
            school: '2kmは何mですか。',
            easy: 'キロメートルをメートルにします。',
            native: {
              AppLanguage.portuguese: '2 km são quantos metros?',
              AppLanguage.tagalog: 'Ilang metro ang 2 km?',
              AppLanguage.vietnamese: '2 km bằng bao nhiêu mét?',
            },
            choices: ['200m', '2000m', '20000m'],
            correct: 1,
            explanation: '1kmは1000mです。2kmは1000mが2つなので、2000mです。',
            explanationRuby:
                '1kmは1000mです。2kmは1000mが2つなので、2000mです。',
            tags: ['check', 'kilometer', 'conversion'],
          ),
          _q(
            id: 25104,
            type: 'compare_length',
            school: '1km500mと1400mでは、どちらが長いですか。',
            easy: '同じ単位にそろえて比べます。',
            native: {
              AppLanguage.portuguese: 'Qual é mais longo: 1 km e 500 m ou 1400 m?',
              AppLanguage.tagalog: 'Alin ang mas mahaba: 1 km at 500 m o 1400 m?',
              AppLanguage.vietnamese: 'Cái nào dài hơn: 1 km 500 m hay 1400 m?',
            },
            choices: ['1km500m', '1400m', '同じ'],
            correct: 0,
            explanation: '1km500mは1500mです。1500mは1400mより長いです。',
            explanationRuby:
                '1km500mは1500mです。1500mは1400mより{長|なが}いです。',
            tags: ['check', 'kilometer', 'compare'],
          ),
          _q(
            id: 25105,
            type: 'route_addition',
            school: '学校から公園まで400m、公園から図書館まで600mです。全部で何kmですか。',
            easy: '2つの道のりを合わせます。',
            native: {
              AppLanguage.portuguese: 'Da escola ao parque 400 m, do parque à biblioteca 600 m. Quantos km ao todo?',
              AppLanguage.tagalog: '400 m mula paaralan hanggang parke, 600 m mula parke hanggang aklatan. Ilang km lahat?',
              AppLanguage.vietnamese: 'Từ trường đến công viên 400 m, từ công viên đến thư viện 600 m. Tổng cộng bao nhiêu km?',
            },
            choices: ['1km', '10km', '1000km'],
            correct: 0,
            explanation: '400mと600mを合わせると1000mです。1000mは1kmです。',
            explanationRuby:
                '400mと600mを{合|あ}わせると1000mです。1000mは1kmです。',
            tags: ['check', 'distance', 'addition'],
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
  return switch (id) {
    21101 => {
      AppLanguage.portuguese: 'Para objetos curtos, como uma mesa, é fácil medir com uma régua. Alinhe o 0 da régua com a ponta.',
      AppLanguage.tagalog: 'Para sa maiikling bagay tulad ng mesa, madaling sukatin gamit ang ruler. Ihanay ang 0 ng ruler sa dulo.',
      AppLanguage.vietnamese: 'Đồ ngắn như cái bàn dễ đo bằng thước kẻ. Đặt vạch 0 của thước sát mép.',
    },
    21102 => {
      AppLanguage.portuguese: 'Para objetos longos, como a sala de aula, é mais fácil medir com uma fita métrica.',
      AppLanguage.tagalog: 'Para sa mahahabang bagay tulad ng silid-aralan, mas madaling sukatin gamit ang tape measure.',
      AppLanguage.vietnamese: 'Đồ dài như phòng học dễ đo hơn bằng thước dây.',
    },
    21103 => {
      AppLanguage.portuguese: 'Quando a ponta esquerda da borracha está no 0, a ponta direita fica na marca de 4 cm.',
      AppLanguage.tagalog: 'Kapag ang kaliwang dulo ng pambura ay nasa 0, ang kanang dulo ay nasa markang 4 cm.',
      AppLanguage.vietnamese: 'Khi mép trái cục tẩy ở vạch 0, mép phải ở vạch 4 cm.',
    },
    21104 => {
      AppLanguage.portuguese: 'A fita métrica também pode acompanhar partes curvas para medir ao redor.',
      AppLanguage.tagalog: 'Ang tape measure ay puwede ring isunod sa baluktot na bahagi para sukatin ang paligid.',
      AppLanguage.vietnamese: 'Thước dây còn uốn theo chỗ cong để đo vòng quanh.',
    },
    21105 => {
      AppLanguage.portuguese: 'Para objetos curtos, como um lápis, é fácil medir com uma régua.',
      AppLanguage.tagalog: 'Para sa maiikling bagay tulad ng lapis, madaling sukatin gamit ang ruler.',
      AppLanguage.vietnamese: 'Đồ ngắn như bút chì dễ đo bằng thước kẻ.',
    },
    22101 => {
      AppLanguage.portuguese: '1000 m e 1 km têm o mesmo comprimento.',
      AppLanguage.tagalog: 'Pareho ang haba ng 1000 m at 1 km.',
      AppLanguage.vietnamese: '1000 m và 1 km dài bằng nhau.',
    },
    22102 => {
      AppLanguage.portuguese: '1 km são 1000 m. 1000 m mais 200 m são 1200 m.',
      AppLanguage.tagalog: '1 km ay 1000 m. 1000 m dagdag 200 m ay 1200 m.',
      AppLanguage.vietnamese: '1 km bằng 1000 m. 1000 m cộng 200 m là 1200 m.',
    },
    22103 => {
      AppLanguage.portuguese: '1 km e 100 m são 1100 m. 1100 m é maior que 900 m.',
      AppLanguage.tagalog: '1 km at 100 m ay 1100 m. Mas mahaba ang 1100 m kaysa 900 m.',
      AppLanguage.vietnamese: '1 km và 100 m là 1100 m. 1100 m dài hơn 900 m.',
    },
    22104 => {
      AppLanguage.portuguese: '800 m mais 600 m são 1400 m. Também podemos escrever 1400 m como 1 km e 400 m.',
      AppLanguage.tagalog: '800 m dagdag 600 m ay 1400 m. Puwede ring isulat ang 1400 m bilang 1 km at 400 m.',
      AppLanguage.vietnamese: '800 m cộng 600 m là 1400 m. 1400 m cũng viết được thành 1 km 400 m.',
    },
    25101 => {
      AppLanguage.portuguese: 'Quando a ponta esquerda da borracha está no 0, a ponta direita fica na marca de 4 cm.',
      AppLanguage.tagalog: 'Kapag ang kaliwang dulo ng pambura ay nasa 0, ang kanang dulo ay nasa markang 4 cm.',
      AppLanguage.vietnamese: 'Khi mép trái cục tẩy ở vạch 0, mép phải ở vạch 4 cm.',
    },
    25102 => {
      AppLanguage.portuguese: 'Para objetos longos, como o corredor, é mais fácil medir com uma fita métrica.',
      AppLanguage.tagalog: 'Para sa mahahabang bagay tulad ng pasilyo, mas madaling sukatin gamit ang tape measure.',
      AppLanguage.vietnamese: 'Đồ dài như hành lang dễ đo hơn bằng thước dây.',
    },
    25103 => {
      AppLanguage.portuguese: '1 km são 1000 m. 2 km são 1000 m duas vezes, então 2000 m.',
      AppLanguage.tagalog: '1 km ay 1000 m. 2 km ay dalawang 1000 m, kaya 2000 m.',
      AppLanguage.vietnamese: '1 km bằng 1000 m. 2 km là hai lần 1000 m, nên 2000 m.',
    },
    25104 => {
      AppLanguage.portuguese: '1 km e 500 m são 1500 m. 1500 m é mais longo que 1400 m.',
      AppLanguage.tagalog: '1 km at 500 m ay 1500 m. Mas mahaba ang 1500 m kaysa 1400 m.',
      AppLanguage.vietnamese: '1 km 500 m là 1500 m. 1500 m dài hơn 1400 m.',
    },
    25105 => {
      AppLanguage.portuguese: '400 m mais 600 m são 1000 m. 1000 m são 1 km.',
      AppLanguage.tagalog: '400 m dagdag 600 m ay 1000 m. 1000 m ay 1 km.',
      AppLanguage.vietnamese: '400 m cộng 600 m là 1000 m. 1000 m là 1 km.',
    },
    22105 => {
      AppLanguage.portuguese: '1600 m são 1000 m mais 600 m. 1000 m são 1 km, então é 1 km e 600 m.',
      AppLanguage.tagalog: '1600 m ay 1000 m dagdag 600 m. 1000 m ay 1 km, kaya 1 km at 600 m.',
      AppLanguage.vietnamese: '1600 m là 1000 m cộng 600 m. 1000 m là 1 km, nên thành 1 km 600 m.',
    },
    _ => const {},
  };
}
