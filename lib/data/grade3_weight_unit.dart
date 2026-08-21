import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';

final List<Lesson> grade3WeightLessons = [
  Lesson(
    id: 23,
    levelId: 3,
    type: LessonType.practice,
    title: 'グラム・キログラム',
    description: 'はかりを使って、gとkgの感覚をつかみます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'weight-gram-kg-learn',
        title: '学習しよう',
        school: 'ものを比べたり、はかりに乗せたりして、重さを考えます。',
        easy: '重い・軽いを比べて、gとkgを考えます。',
        native: {
          AppLanguage.portuguese:
              'Vamos comparar pesos e usar uma balança para entender g e kg.',
          AppLanguage.tagalog:
              'Ihambing natin ang bigat at gumamit ng timbangan para maintindihan ang g at kg.',
          AppLanguage.vietnamese:
              'Hãy so sánh khối lượng và dùng cân để hiểu g và kg.',
        },
      ),
      _learn(
        id: 'weight-gram-kg-words',
        title: 'ことばを知ろう',
        school: '重さやはかりのことばを確認します。',
        easy: '重さの言葉です。',
      ),
      LessonStep(
        id: 'weight-gram-kg-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに考えよう',
        questions: [
          _q(
            id: 23101,
            type: 'read_weight_scale',
            school: 'はかりを見て、重さを読みましょう。重さは何gですか。',
            easy: 'はかりの目盛りを見ます。',
            native: {
              AppLanguage.portuguese:
                  'Observe a balança e leia o peso. Quantos gramas são?',
              AppLanguage.tagalog:
                  'Tingnan ang timbangan at basahin ang timbang. Ilang gramo?',
              AppLanguage.vietnamese:
                  'Nhìn cân và đọc khối lượng. Bao nhiêu gam?',
            },
            questionTextRuby:
                'はかりを{見|み}て、{重|おも}さを{読|よ}みましょう。{重|おも}さは{何|なん}gですか。',
            choices: ['250g', '350g', '450g'],
            correct: 1,
            explanation: '300gと400gの間の目盛りを見ると、350gです。',
            explanationRuby:
                '300gと400gの{間|あいだ}の{目|め}もりを{見|み}ると、350gです。',
            diagramType: 'weight_scale',
            diagramData: {'grams': '350'},
            tags: ['weight', 'gram', 'scale_reading'],
          ),
          _q(
            id: 23102,
            type: 'unit_sense',
            school: 'えんぴつの重さを表すなら、どちらが自然ですか。',
            easy: 'えんぴつは軽いものです。',
            native: {
              AppLanguage.portuguese:
                  'Para mostrar o peso de um lápis, qual parece natural?',
              AppLanguage.tagalog:
                  'Para ipakita ang bigat ng lapis, alin ang natural?',
              AppLanguage.vietnamese:
                  'Để ghi khối lượng bút chì, cách nào tự nhiên hơn?',
            },
            questionTextRuby:
                'えんぴつの{重|おも}さを{表|あらわ}すなら、どちらが{自然|しぜん}ですか。',
            choices: ['10g', '10kg'],
            correct: 0,
            explanation: 'えんぴつは軽いので、gで表すと分かりやすいです。',
            explanationRuby:
                'えんぴつは{軽|かる}いので、gで{表|あらわ}すとわかりやすいです。',
            tags: ['weight', 'gram', 'unit_sense'],
          ),
          _q(
            id: 23103,
            type: 'kg_g_conversion',
            school: '1kg300gは何gですか。',
            easy: '1kgは1000gです。',
            native: {
              AppLanguage.portuguese: '1 kg e 300 g são quantos gramas?',
              AppLanguage.tagalog: 'Ilang gramo ang 1 kg at 300 g?',
              AppLanguage.vietnamese: '1 kg và 300 g bằng bao nhiêu gam?',
            },
            questionTextRuby: '1kg300gは{何|なん}gですか。',
            choices: ['1030g', '1300g', '3000g'],
            correct: 1,
            explanation: '1kgは1000gです。1000gと300gを合わせると1300gです。',
            explanationRuby:
                '1kgは1000gです。1000gと300gを{合|あ}わせると1300gです。',
            tags: ['weight', 'kilogram', 'conversion'],
          ),
        ],
      ),
      LessonStep(
        id: 'weight-gram-kg-practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 23104,
            type: 'unit_sense',
            school: 'ランドセルの重さを表すなら、どちらが自然ですか。',
            easy: 'ランドセルは、えんぴつよりずっと重いです。',
            native: {
              AppLanguage.portuguese: 'Para mostrar o peso da mochila, qual parece natural?',
              AppLanguage.tagalog: 'Para ipakita ang bigat ng bag, alin ang natural?',
              AppLanguage.vietnamese: 'Để ghi khối lượng cặp sách, cách nào tự nhiên hơn?',
            },
            questionTextRuby:
                'ランドセルの{重|おも}さを{表|あらわ}すなら、どちらが{自然|しぜん}ですか。',
            choices: ['4g', '4kg'],
            correct: 1,
            explanation: 'ランドセルのように重いものは、kgで表すと分かりやすいです。',
            explanationRuby:
                'ランドセルのように{重|おも}いものは、kgで{表|あらわ}すとわかりやすいです。',
            tags: ['weight', 'kilogram', 'unit_sense'],
          ),
          _q(
            id: 23105,
            type: 'g_to_kg',
            school: '1700gは、1kg何gですか。',
            easy: '1000gを1kgにします。',
            native: {
              AppLanguage.portuguese: '1700 g são 1 kg e quantos gramas?',
              AppLanguage.tagalog: '1700 g ay 1 kg at ilang gramo?',
              AppLanguage.vietnamese: '1700 g bằng 1 kg bao nhiêu gam?',
            },
            questionTextRuby: '1700gは、1kg{何|なん}gですか。',
            choices: ['1kg70g', '1kg700g', '17kg'],
            correct: 1,
            explanation: '1700gは、1000gと700gです。1000gは1kgなので、1kg700gです。',
            explanationRuby:
                '1700gは、1000gと700gです。1000gは1kgなので、1kg700gです。',
            tags: ['weight', 'kilogram', 'conversion'],
          ),
        ],
      ),
      LessonStep(
        id: 'weight-gram-kg-japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 23106,
            type: 'read_weight_scale',
            school: 'はかりを見て、重さを読みましょう。重さは何gですか。',
            easy: 'はかりの目盛りを読みます。',
            questionTextRuby:
                'はかりを{見|み}て、{重|おも}さを{読|よ}みましょう。{重|おも}さは{何|なん}gですか。',
            choices: ['600g', '700g', '800g'],
            correct: 1,
            explanation: '針が700gの目盛りを指しているので、重さは700gです。',
            explanationRuby:
                '{針|はり}が700gの{目|め}もりを{指|さ}しているので、{重|おも}さは700gです。',
            diagramType: 'weight_scale',
            diagramData: {'grams': '700'},
            tags: ['weight', 'gram', 'scale_reading'],
          ),
        ],
      ),
    ],
  ),
  Lesson(
    id: 24,
    levelId: 3,
    type: LessonType.practice,
    title: 'トン',
    description: 'とても重いものを、tで表すよさを考えます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'weight-ton-learn',
        title: '学習しよう',
        school: 'とても重いものは、トンで表すことがあります。',
        easy: 'とても重いものに使う単位です。',
        native: {
          AppLanguage.portuguese:
              'Para coisas muito pesadas, podemos usar toneladas.',
          AppLanguage.tagalog:
              'Para sa napakabibigat, puwedeng gamitin ang tonelada.',
          AppLanguage.vietnamese:
              'Với đồ rất nặng, có thể dùng tấn.',
        },
      ),
      _learn(
        id: 'weight-ton-words',
        title: 'ことばを知ろう',
        school: 'トンや単位のことばを確認します。',
        easy: 'とても重いものの言葉です。',
      ),
      LessonStep(
        id: 'weight-ton-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに考えよう',
        questions: [
          _q(
            id: 24101,
            type: 'ton_relation',
            school: '1000kgは何tですか。',
            easy: '1000kgと1tは同じ重さです。',
            native: {
              AppLanguage.portuguese: '1000 kg são quantas toneladas?',
              AppLanguage.tagalog: 'Ilang tonelada ang 1000 kg?',
              AppLanguage.vietnamese: '1000 kg bằng bao nhiêu tấn?',
            },
            questionTextRuby: '1000kgは{何|なん}tですか。',
            choices: ['1t', '10t', '100t'],
            correct: 0,
            explanation: '1000kgを1トンといいます。トンはtと書きます。',
            explanationRuby: '1000kgを1トンといいます。トンはtと{書|か}きます。',
            tags: ['weight', 'ton', 'conversion'],
          ),
          _q(
            id: 24102,
            type: 'unit_sense',
            school: 'トラックの重さを表すなら、どの単位が自然ですか。',
            easy: 'トラックはとても重いものです。',
            native: {
              AppLanguage.portuguese:
                  'Para mostrar o peso de um caminhão, qual unidade parece natural?',
              AppLanguage.tagalog:
                  'Para ipakita ang bigat ng trak, aling yunit ang natural?',
              AppLanguage.vietnamese:
                  'Để ghi khối lượng xe tải, đơn vị nào tự nhiên hơn?',
            },
            questionTextRuby:
                'トラックの{重|おも}さを{表|あらわ}すなら、どの{単位|たんい}が{自然|しぜん}ですか。',
            choices: ['g', 'kg', 't'],
            correct: 2,
            explanation: 'トラックのようにとても重いものは、tで表すと分かりやすいです。',
            explanationRuby:
                'トラックのようにとても{重|おも}いものは、tで{表|あらわ}すとわかりやすいです。',
            tags: ['weight', 'ton', 'unit_sense'],
          ),
        ],
      ),
      LessonStep(
        id: 'weight-ton-japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 24103,
            type: 'unit_sense',
            school: '消しゴムの重さを表すなら、どの単位が自然ですか。',
            easy: '消しゴムは軽いものです。',
            choices: ['g', 'kg', 't'],
            correct: 0,
            explanation: '消しゴムのように軽いものは、gで表すと分かりやすいです。',
            tags: ['weight', 'gram', 'unit_sense'],
          ),
          _q(
            id: 24104,
            type: 'unit_sense',
            school: 'ゾウの重さを表すなら、どの単位が自然ですか。',
            easy: 'ゾウはとても重い動物です。',
            choices: ['g', 'kg', 't'],
            correct: 2,
            explanation: 'ゾウのようにとても重いものは、tで表すと分かりやすいです。',
            tags: ['weight', 'ton', 'unit_sense'],
          ),
        ],
      ),
    ],
  ),
  Lesson(
    id: 26,
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
        id: 'weight-check',
        type: LessonStepType.independentPractice,
        title: 'たしかめ問題',
        questions: [
          _q(
            id: 26101,
            type: 'read_weight_scale',
            school: 'はかりの針を見て、重さは何gですか。',
            easy: 'はかりの目もりを読みます。',
            native: {
              AppLanguage.portuguese: 'Olhando o ponteiro da balança, quantos gramas são?',
              AppLanguage.tagalog: 'Tingnan ang karayom ng timbangan. Ilang gramo?',
              AppLanguage.vietnamese: 'Nhìn kim cân, bao nhiêu gam?',
            },
            choices: ['250g', '350g', '450g'],
            correct: 1,
            explanation: '300gと400gの間の目もりを見ると、350gです。',
            explanationRuby:
                '300gと400gの{間|あいだ}の{目|め}もりを{見|み}ると、350gです。',
            diagramType: 'weight_scale',
            diagramData: const {'grams': '350'},
            tags: ['check', 'gram', 'scale_reading'],
          ),
          _q(
            id: 26102,
            type: 'unit_sense',
            school: 'りんごの重さを表すなら、どちらが自然ですか。',
            easy: 'りんごに合う単位を選びます。',
            native: {
              AppLanguage.portuguese: 'Para mostrar o peso de uma maçã, qual parece natural?',
              AppLanguage.tagalog: 'Para ipakita ang bigat ng mansanas, alin ang natural?',
              AppLanguage.vietnamese: 'Để ghi khối lượng quả táo, cách nào tự nhiên hơn?',
            },
            choices: ['250g', '250kg'],
            correct: 0,
            explanation: 'りんごのように手で持てる重さは、gで表すと分かりやすいです。',
            explanationRuby:
                'りんごのように{手|て}で{持|も}てる{重|おも}さは、gで{表|あらわ}すと{分|わ}かりやすいです。',
            tags: ['check', 'gram', 'unit_sense'],
          ),
          _q(
            id: 26103,
            type: 'kg_g_conversion',
            school: '1kg500gは何gですか。',
            easy: '1kgを1000gにして考えます。',
            native: {
              AppLanguage.portuguese: '1 kg e 500 g são quantos gramas?',
              AppLanguage.tagalog: 'Ilang gramo ang 1 kg at 500 g?',
              AppLanguage.vietnamese: '1 kg và 500 g bằng bao nhiêu gam?',
            },
            choices: ['1050g', '1500g', '5000g'],
            correct: 1,
            explanation: '1kgは1000gです。1000gと500gを合わせると、1500gです。',
            explanationRuby:
                '1kgは1000gです。1000gと500gを{合|あ}わせると、1500gです。',
            tags: ['check', 'kilogram', 'conversion'],
          ),
          _q(
            id: 26104,
            type: 'ton_relation',
            school: '3000kgは何tですか。',
            easy: '1000kgを1tにします。',
            native: {
              AppLanguage.portuguese: '3000 kg são quantas toneladas?',
              AppLanguage.tagalog: 'Ilang tonelada ang 3000 kg?',
              AppLanguage.vietnamese: '3000 kg bằng bao nhiêu tấn?',
            },
            choices: ['3t', '30t', '300t'],
            correct: 0,
            explanation: '1000kgを1tといいます。3000kgは1000kgが3つなので、3tです。',
            explanationRuby:
                '1000kgを1tといいます。3000kgは1000kgが3つなので、3tです。',
            tags: ['check', 'ton', 'conversion'],
          ),
          _q(
            id: 26105,
            type: 'unit_sense',
            school: 'ゾウの重さを表すなら、どの単位が自然ですか。',
            easy: 'とても重いものに合う単位を選びます。',
            native: {
              AppLanguage.portuguese: 'Para mostrar o peso de um elefante, qual unidade parece natural?',
              AppLanguage.tagalog: 'Para ipakita ang bigat ng elepante, aling yunit ang natural?',
              AppLanguage.vietnamese: 'Để ghi khối lượng con voi, đơn vị nào tự nhiên hơn?',
            },
            choices: ['g', 'kg', 't'],
            correct: 2,
            explanation: 'ゾウのようにとても重いものは、tで表すと分かりやすいです。',
            explanationRuby:
                'ゾウのようにとても{重|おも}いものは、tで{表|あらわ}すと{分|わ}かりやすいです。',
            tags: ['check', 'ton', 'unit_sense'],
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
  Map<AppLanguage, String> native = const {},
  String questionTextRuby = '',
  required List<String> choices,
  List<String> choicesRuby = const [],
  required int correct,
  required String explanation,
  String explanationRuby = '',
  String diagramType = '',
  Map<String, String> diagramData = const {},
  required List<String> tags,
}) {
  return Question(
    id: id,
    type: type,
    unitId: 'grade3_weight',
    promptSchoolJa: school,
    promptEasyJa: easy,
    promptNative: native,
    questionTextRuby: questionTextRuby,
    choices: choices,
    choicesRuby: choicesRuby,
    correctAnswer: correct,
    explanationEasyJa: explanation,
    explanation: explanation,
    explanationRuby: explanationRuby,
    explanationNative: _weightExplanationNative(id),
    diagramType: diagramType,
    diagramData: diagramData,
    tags: ['grade3', 'math', 'weight', ...tags],
    grade: 3,
    subject: 'math',
    unit: 'weight',
  );
}

Map<AppLanguage, String> _weightExplanationNative(int id) {
  return switch (id) {
    23101 => {
      AppLanguage.portuguese: 'A marca entre 300 g e 400 g é 350 g.',
      AppLanguage.tagalog: 'Ang marka sa pagitan ng 300 g at 400 g ay 350 g.',
      AppLanguage.vietnamese: 'Vạch giữa 300 g và 400 g là 350 g.',
    },
    23102 => {
      AppLanguage.portuguese: 'Um lápis é leve, então g é uma unidade natural.',
      AppLanguage.tagalog: 'Magaan ang lapis, kaya natural ang yunit na g.',
      AppLanguage.vietnamese: 'Bút chì nhẹ nên dùng g thì tự nhiên.',
    },
    23103 => {
      AppLanguage.portuguese: '1 kg é 1000 g. 1000 g mais 300 g são 1300 g.',
      AppLanguage.tagalog: '1 kg ay 1000 g. 1000 g dagdag 300 g ay 1300 g.',
      AppLanguage.vietnamese: '1 kg bằng 1000 g. 1000 g cộng 300 g là 1300 g.',
    },
    23104 => {
      AppLanguage.portuguese: 'Uma mochila é pesada, então kg é mais natural.',
      AppLanguage.tagalog: 'Mabigat ang bag, kaya mas natural ang kg.',
      AppLanguage.vietnamese: 'Cặp sách nặng nên dùng kg thì tự nhiên hơn.',
    },
    23105 => {
      AppLanguage.portuguese: '1700 g são 1000 g e 700 g. 1000 g é 1 kg.',
      AppLanguage.tagalog: '1700 g ay 1000 g at 700 g. 1000 g ay 1 kg.',
      AppLanguage.vietnamese: '1700 g là 1000 g và 700 g. 1000 g là 1 kg.',
    },
    23106 => {
      AppLanguage.portuguese: 'O ponteiro aponta para 700 g.',
      AppLanguage.tagalog: 'Tumakdo ang karayom sa 700 g.',
      AppLanguage.vietnamese: 'Kim cân chỉ 700 g.',
    },
    24101 => {
      AppLanguage.portuguese: '1000 kg é 1 tonelada. Tonelada se escreve t.',
      AppLanguage.tagalog: '1000 kg ay 1 tonelada. Ang tonelada ay sinusulat na t.',
      AppLanguage.vietnamese: '1000 kg là 1 tấn. Tấn viết là t.',
    },
    24102 => {
      AppLanguage.portuguese: 'Um caminhão é muito pesado, então t é mais natural.',
      AppLanguage.tagalog: 'Napakabigat ng trak, kaya mas natural ang t.',
      AppLanguage.vietnamese: 'Xe tải rất nặng nên dùng t thì tự nhiên hơn.',
    },
    24103 => {
      AppLanguage.portuguese: 'Uma borracha é leve, então g é mais natural.',
      AppLanguage.tagalog: 'Magaan ang pambura, kaya mas natural ang g.',
      AppLanguage.vietnamese: 'Cục tẩy nhẹ nên dùng g thì tự nhiên hơn.',
    },
    24104 => {
      AppLanguage.portuguese: 'Um elefante é muito pesado, então t é mais natural.',
      AppLanguage.tagalog: 'Napakabigat ng elepante, kaya mas natural ang t.',
      AppLanguage.vietnamese: 'Con voi rất nặng nên dùng t thì tự nhiên hơn.',
    },
    26101 => {
      AppLanguage.portuguese: 'A marca entre 300 g e 400 g é 350 g.',
      AppLanguage.tagalog: 'Ang marka sa pagitan ng 300 g at 400 g ay 350 g.',
      AppLanguage.vietnamese: 'Vạch giữa 300 g và 400 g là 350 g.',
    },
    26102 => {
      AppLanguage.portuguese: 'Uma maçã cabe na mão, então g é uma unidade natural.',
      AppLanguage.tagalog: 'Kaya hawakan ang mansanas, kaya natural ang yunit na g.',
      AppLanguage.vietnamese: 'Quả táo cầm tay được nên dùng g thì tự nhiên.',
    },
    26103 => {
      AppLanguage.portuguese: '1 kg é 1000 g. 1000 g mais 500 g são 1500 g.',
      AppLanguage.tagalog: '1 kg ay 1000 g. 1000 g dagdag 500 g ay 1500 g.',
      AppLanguage.vietnamese: '1 kg bằng 1000 g. 1000 g cộng 500 g là 1500 g.',
    },
    26104 => {
      AppLanguage.portuguese: '1000 kg é 1 t. 3000 kg são 3 t.',
      AppLanguage.tagalog: '1000 kg ay 1 t. 3000 kg ay 3 t.',
      AppLanguage.vietnamese: '1000 kg là 1 t. 3000 kg là 3 t.',
    },
    26105 => {
      AppLanguage.portuguese: 'Um elefante é muito pesado, então t é mais natural.',
      AppLanguage.tagalog: 'Napakabigat ng elepante, kaya mas natural ang t.',
      AppLanguage.vietnamese: 'Con voi rất nặng nên dùng t thì tự nhiên hơn.',
    },
    _ => const {},
  };
}
