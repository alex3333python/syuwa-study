import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';

// Grade 3 division with remainders follows the same card-and-sublesson pattern
// as grade3_division_unit.dart, but keeps values small and one-digit divisors.
final List<Lesson> grade3DivisionRemainderLessons = [
  Lesson(
    id: 12,
    levelId: 2,
    type: LessonType.practice,
    title: 'あまりのあるわり算',
    description: '分けたあとに残る数を、式と図で考えます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'division-remainder-basic-learn',
        title: '学習しよう',
        school: '7このいちごを3人で同じ数ずつ分けます。1人分は2こで、1こ残ります。この残った数を「あまり」といいます。',
        easy: '分けたあとに残る数が、あまりです。',
      ),
      _learn(
        id: 'division-remainder-basic-words',
        title: 'ことばを知ろう',
        school: 'このレッスンで使うことばは「あまり」「わる数」「わられる数」「わりきれる」です。',
        easy: 'あまりのある式を読むためのことばです。',
      ),
      LessonStep(
        id: 'grade3_remainder_1_guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに解こう',
        questions: [
          _q(
            id: 12101,
            type: 'select_picture',
            school: '5このあめを2こずつ分けます。何こあまりますか。',
            easy: 'あめ5こを2こずつにします。残るあめは何こですか。',
            questionTextRuby: '5このあめを2こずつ{分|わ}けます。{何こ|なんこ}あまりますか。',
            choices: ['0こ', '1こ', '2こ'],
            correct: 1,
            explanation: '2こずつのまとまりが2つできて、1こ残ります。',
            explanationRuby: '2こずつのまとまりが2つできて、1こ{残|のこ}ります。',
            vocabulary: ['あまり', '残る'],
            tags: ['remainder', 'select_picture'],
            native: {
              AppLanguage.portuguese:
                  'Dividimos 5 balas em grupos de 2. Quantas balas sobram?',
              AppLanguage.tagalog:
                  'Hatiin ang 5 kendi nang tig-2. Ilang kendi ang matitira?',
              AppLanguage.vietnamese:
                  'Chia 5 viên kẹo thành nhóm 2. Còn lại bao nhiêu viên?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  'Conseguimos fazer 2 grupos de 2, e sobra 1 bala.',
              AppLanguage.tagalog:
                  'Nakagawa tayo ng 2 grupong tig-2, at 1 kendi ang natira.',
              AppLanguage.vietnamese:
                  'Làm được 2 nhóm 2, còn dư 1 viên kẹo.',
            },
            equationHint: '5 ÷ 2 = 2 あまり 1',
            visualHint: '2こずつのまとまりを作り、残った1こを見る。',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: '🍬',
            itemUnit: 'こ',
            totalCount: 5,
            groupCount: 2,
            perGroupCount: 2,
            remainderCount: 1,
          ),
          _q(
            id: 12102,
            type: 'number_input',
            school: '10このクッキーを4こずつ分けます。何こあまりますか。',
            easy: 'クッキー10こを4こずつにします。残りは何こですか。',
            questionTextRuby: '10このクッキーを4こずつ{分|わ}けます。{何こ|なんこ}あまりますか。',
            choices: ['0', '1', '2', '4'],
            correct: 2,
            explanation: '4こずつのまとまりが2つできて、2こ残ります。',
            explanationRuby: '4こずつのまとまりが2つできて、2こ{残|のこ}ります。',
            vocabulary: ['あまり', 'まとまり'],
            tags: ['remainder_calculation'],
            native: {
              AppLanguage.portuguese:
                  'Dividimos 10 biscoitos em grupos de 4. Quantos biscoitos sobram?',
              AppLanguage.tagalog:
                  'Hatiin ang 10 biskwit nang tig-4. Ilang biskwit ang matitira?',
              AppLanguage.vietnamese:
                  'Chia 10 cái bánh thành nhóm 4. Còn lại bao nhiêu cái?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  'Conseguimos fazer 2 grupos de 4, e sobram 2 biscoitos.',
              AppLanguage.tagalog:
                  'Nakagawa tayo ng 2 grupong tig-4, at 2 biskwit ang natira.',
              AppLanguage.vietnamese:
                  'Làm được 2 nhóm 4, còn dư 2 cái bánh.',
            },
            equationHint: '10 ÷ 4 = 2 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: '🍪',
            itemUnit: 'こ',
            totalCount: 10,
            groupCount: 2,
            perGroupCount: 4,
            remainderCount: 2,
          ),
          _q(
            id: 12103,
            type: 'select_word_meaning',
            school: '「あまり」とは何ですか。',
            easy: '「あまり」は、どの数のことですか。',
            questionTextRuby: '「あまり」とは{何|なん}ですか。',
            choicesRuby: [
              '{分|わ}けたあとに{残|のこ}る{数|かず}',
              '{全部|ぜんぶ}の{数|かず}',
              'かけ{算|ざん}の{答|こた}え',
            ],
            choices: ['分けたあとに残る数', 'ぜんぶの数', 'かけ算の答え'],
            correct: 0,
            explanation: 'あまりは、分けたあとに残る数です。',
            explanationRuby: 'あまりは、{分|わ}けたあとに{残|のこ}る{数|かず}です。',
            vocabulary: ['あまり'],
            tags: ['select_word_meaning', 'vocabulary'],
            native: {
              AppLanguage.portuguese: 'O que significa “resto” na divisão?',
              AppLanguage.tagalog: 'Ano ang ibig sabihin ng “sobra” sa dibisyon?',
              AppLanguage.vietnamese: '「Số dư」trong phép chia nghĩa là gì?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  'O resto é o número que sobra depois de dividir.',
              AppLanguage.tagalog:
                  'Ang sobra ay ang numerong natitira pagkatapos maghati.',
              AppLanguage.vietnamese:
                  'Số dư là số còn lại sau khi chia.',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_1_practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 12104,
            type: 'remainder_check',
            school: '12このクッキーを4こずつ分けると、あまりはありますか。',
            easy: 'クッキー12こを4こずつにします。残りはありますか。',
            questionTextRuby:
                '12このクッキーを4こずつ{分|わ}けると、あまりはありますか。',
            choices: ['ある', 'ない'],
            correct: 1,
            explanation: 'クッキーを4こずつ分けると、3組できて、あまりはありません。',
            explanationRuby:
                'クッキーを4こずつ{分|わ}けると、3{組|くみ}できて、あまりはありません。',
            vocabulary: ['ぴったり', 'わりきれる'],
            tags: ['remainder_check'],
            native: {
              AppLanguage.portuguese:
                  'Se dividirmos 12 biscoitos em grupos de 4, sobra algum biscoito?',
              AppLanguage.tagalog:
                  'Kung hatiin ang 12 biskwit nang tig-4, may matitira ba?',
              AppLanguage.vietnamese:
                  'Nếu chia 12 cái bánh thành nhóm 4 thì còn dư không?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  'Fazemos 3 grupos de 4 biscoitos. Não sobra nenhum biscoito.',
              AppLanguage.tagalog:
                  '3 grupong tig-4 na biskwit. Walang natitirang biskwit.',
              AppLanguage.vietnamese:
                  'Làm 3 nhóm 4 cái bánh. Không còn cái nào.',
            },
            equationHint: '12 ÷ 4 = 3',
            visualType: QuestionVisualType.divisionSharing,
            itemEmoji: 'cookie',
            itemUnit: 'こ',
            totalCount: 12,
            groupCount: 3,
            perGroupCount: 4,
          ),
          _q(
            id: 12105,
            type: 'remainder_check',
            school: '14このあめを4こずつ分けると、あまりはありますか。',
            easy: 'あめ14こを4こずつにします。残りはありますか。',
            questionTextRuby:
                '14このあめを4こずつ{分|わ}けると、あまりはありますか。',
            choices: ['ある', 'ない'],
            correct: 0,
            explanation: 'あめを4こずつ分けると、3組できて、2こ残ります。',
            explanationRuby:
                'あめを4こずつ{分|わ}けると、3{組|くみ}できて、2こ{残|のこ}ります。',
            vocabulary: ['わりきれない'],
            tags: ['remainder_check'],
            native: {
              AppLanguage.portuguese:
                  'Se dividirmos 14 balas em grupos de 4, sobra alguma bala?',
              AppLanguage.tagalog:
                  'Kung hatiin ang 14 kendi nang tig-4, may matitira ba?',
              AppLanguage.vietnamese:
                  'Nếu chia 14 viên kẹo thành nhóm 4 thì còn dư không?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  'Fazemos 3 grupos de 4 balas, e sobram 2 balas.',
              AppLanguage.tagalog:
                  '3 grupong tig-4 na kendi, at 2 kendi ang natira.',
              AppLanguage.vietnamese:
                  'Làm 3 nhóm 4 viên kẹo, còn dư 2 viên.',
            },
            equationHint: '14 ÷ 4 = 3 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: 'candy',
            itemUnit: 'こ',
            totalCount: 14,
            groupCount: 3,
            perGroupCount: 4,
            remainderCount: 2,
          ),
          _q(
            id: 12106,
            type: 'number_input',
            school: '13このシールを5こずつ分けます。何こあまりますか。',
            easy: 'シール13こを5こずつにします。残りは何こですか。',
            questionTextRuby: '13このシールを5こずつ{分|わ}けます。{何こ|なんこ}あまりますか。',
            choices: ['1', '2', '3', '5'],
            correct: 2,
            explanation: '5こずつのまとまりが2つできて、3こ残ります。',
            explanationRuby: '5こずつのまとまりが2つできて、3こ{残|のこ}ります。',
            vocabulary: ['あまり'],
            tags: ['remainder_calculation'],
            native: {
              AppLanguage.portuguese:
                  'Dividimos 13 adesivos em grupos de 5. Quantos adesivos sobram?',
              AppLanguage.tagalog:
                  'Hatiin ang 13 sticker nang tig-5. Ilang sticker ang matitira?',
              AppLanguage.vietnamese:
                  'Chia 13 tem thành nhóm 5. Còn lại bao nhiêu tem?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  'Conseguimos fazer 2 grupos de 5, e sobram 3 adesivos.',
              AppLanguage.tagalog:
                  'Nakagawa tayo ng 2 grupong tig-5, at 3 sticker ang natira.',
              AppLanguage.vietnamese:
                  'Làm được 2 nhóm 5, còn dư 3 tem.',
            },
            equationHint: '13 ÷ 5 = 2 あまり 3',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: 'sticker',
            itemUnit: 'こ',
            totalCount: 13,
            groupCount: 2,
            perGroupCount: 5,
            remainderCount: 3,
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_1_japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 12107,
            type: 'select_word_meaning',
            school: '「ぴったり分けられる」とはどんな意味ですか。',
            easy: '「ぴったり分けられる」は、どういうことですか。',
            choices: ['あまりが出ない', 'あまりがたくさん出る', '分けられない'],
            correct: 0,
            explanation: 'ぴったり分けられるとき、あまりは出ません。',
            vocabulary: ['ぴったり', 'わりきれる'],
            tags: ['select_word_meaning', 'vocabulary'],
          ),
          _q(
            id: 12108,
            type: 'remainder_check',
            school: '15このシールを5こずつ分けると、あまりは0です。これは正しいですか。',
            easy: 'シール15こを5こずつにすると、残りはありません。正しいですか。',
            choices: ['正しい', '正しくない'],
            correct: 0,
            explanation: 'シールを5こずつ分けると、3組できて、あまりはありません。',
            vocabulary: ['あまり0'],
            tags: ['remainder_check'],
            equationHint: '15 ÷ 5 = 3',
            visualType: QuestionVisualType.divisionSharing,
            itemEmoji: 'sticker',
            itemUnit: 'こ',
            totalCount: 15,
            groupCount: 3,
            perGroupCount: 5,
          ),
        ],
      ),
      _summary(
        id: 'grade3_remainder_1_summary',
        school: 'ぴったり分けられずに残る数を「あまり」といいます。',
        easy: '分けたあとに残った数が、あまりです。',
        native: {
          AppLanguage.portuguese:
              'O número que sobra depois de dividir é chamado de resto.',
          AppLanguage.tagalog:
              'Ang numerong natitira pagkatapos maghati ay tinatawag na sobra.',
          AppLanguage.vietnamese:
              'Số còn lại sau khi chia được gọi là số dư.',
        },
      ),
    ],
  ),
  Lesson(
    id: 13,
    levelId: 2,
    type: LessonType.practice,
    title: 'あまりを式で表す',
    description: '17 ÷ 5 = 3 あまり 2 のように、あまりのある式を書きます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'grade3_remainder_2_learn',
        title: '学習しよう',
        school:
            '17 ÷ 5 を考えます。5×3=15 で17に近い数になります。17-15=2 なので、17÷5=3 あまり2です。あまりは、わる数の5より小さくなります。',
        easy: 'わる数を何回作れるか考えます。残った数を「あまり」として書きます。',
      ),
      _learn(
        id: 'grade3_remainder_2_words',
        title: 'ことばを知ろう',
        school: '大事な言葉は「商」「あまり」「わる数」「わられる数」「式で表す」です。',
        easy: '「商」は、わり算の答えの大きい数です。「あまり」は残った数です。',
      ),
      LessonStep(
        id: 'grade3_remainder_2_guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに解こう',
        questions: [
          _q(
            id: 12201,
            type: 'remainder_calculation',
            school: '13 ÷ 4 = 3 あまり□。あまりはいくつですか。',
            easy: '13を4でわります。4×3=12。残りはいくつですか。',
            questionTextRuby: '13を4でわります。4×3=12。{残り|のこり}はいくつですか。',
            choices: ['1', '2', '3', '4'],
            correct: 0,
            correctAnswerText: '3 あまり 1',
            correctAnswerTextRuby: '3 あまり 1',
            explanation: '13-12=1 なので、13÷4=3 あまり1です。',
            explanationRuby:
                '13 - 12 = 1 なので、1こ{余|あま}ります。だから、13 ÷ 4 = 3 あまり 1 です。',
            formulaExplanation:
                '13 ÷ 4 は、13を4つずつ分けるという意味です。\n3は、4つずつのまとまりの数です。\nあまりの1は、分けきれずに残った数です。',
            formulaExplanationRuby:
                '13 ÷ 4 は、13こを4{人|にん}に{同|おな}じ{数|かず}ずつ{分|わ}けるという{意味|いみ}です。\n{答え|こたえ}の3は、{1人|ひとり}{分|ぶん}の{数|かず}です。\nあまりの1は、{分|わ}けきれずに{残|のこ}った{数|かず}です。',
            languagePoint: '「あまり」は、同じ数ずつ分けたあとに残る数です。',
            languagePointRuby:
                '「あまり」は、{同|おな}じ{数|かず}ずつ{分|わ}けたあとに{残|のこ}る{数|かず}です。',
            vocabularyEntries: _remainderVocabulary,
            visualType: QuestionVisualType.divisionRemainder,
            visualTitle: '13このあめを4人で分ける図',
            visualDescription: '4人のカードに、あめが3こずつ入って、1こあまります。',
            itemLabel: 'あめ',
            itemEmoji: '🍬',
            itemUnit: 'こ',
            totalCount: 13,
            groupCount: 4,
            perGroupCount: 3,
            remainderCount: 1,
            vocabulary: ['あまり', '式で表す'],
            tags: ['remainder_calculation'],
            equationHint: '13 ÷ 4 = 3 あまり 1',
          ),
          _q(
            id: 12202,
            type: 'fill_blank',
            school: '17 ÷ 5 = 3 あまり□。□に入る数は何ですか。',
            easy: '17を5でわると、3こずつ作れて、何こ残りますか。',
            questionTextRuby: '17を5でわると、3こずつ{作|つく}れて、{何こ|なんこ}{残|のこ}りますか。',
            choices: ['1', '2', '3', '5'],
            correct: 1,
            explanation: '5×3=15、17-15=2 なので、あまりは2です。',
            explanationRuby: '5×3=15、17-15=2 なので、あまりは2です。',
            vocabularyEntries: _remainderVocabulary,
            visualType: QuestionVisualType.divisionRemainder,
            visualTitle: '17まいのシールを5人で分ける図',
            visualDescription: '5人のカードに、シールが3まいずつ入って、2まいあまります。',
            itemLabel: 'シール',
            itemEmoji: '⭐',
            itemUnit: 'まい',
            totalCount: 17,
            groupCount: 5,
            perGroupCount: 3,
            remainderCount: 2,
            vocabulary: ['□', 'あまり'],
            tags: ['remainder_calculation', 'fill_blank'],
            equationHint: '17 ÷ 5 = 3 あまり 2',
          ),
          _q(
            id: 12203,
            type: 'remainder_calculation',
            school: '20 ÷ 6 を計算しましょう。',
            easy: '20を6でわります。答えはどれですか。',
            choices: ['3 あまり 1', '3 あまり 2', '4 あまり 2'],
            correct: 1,
            explanation: '6×3=18、20-18=2 なので、3 あまり2です。',
            vocabulary: ['商', 'あまり'],
            tags: ['remainder_calculation'],
            equationHint: '20 ÷ 6 = 3 あまり 2',
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_2_practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 12204,
            type: 'remainder_calculation',
            school: '14 ÷ 3 の答えはどれですか。',
            easy: '14を3でわります。答えはどれですか。',
            choices: ['4 あまり 2', '3 あまり 2', '5 あまり 1'],
            correct: 0,
            explanation: '3×4=12、14-12=2 なので、4 あまり2です。',
            vocabulary: ['商', 'あまり'],
            tags: ['remainder_calculation'],
            equationHint: '14 ÷ 3 = 4 あまり 2',
          ),
          _q(
            id: 12205,
            type: 'remainder_check',
            school: '19 ÷ 4 = 3 あまり7 は正しいですか。',
            easy: 'あまり7は、わる数4より小さいですか。',
            choices: ['正しい', '正しくない'],
            correct: 1,
            explanation: 'あまり7は、わる数4より大きいです。もう1つまとまりを作れます。',
            vocabulary: ['わる数', 'あまり'],
            tags: ['remainder_check'],
            equationHint: '19 ÷ 4 = 4 あまり 3',
            thinkingHint: 'あまりは、わる数より小さくします。',
          ),
          _q(
            id: 12206,
            type: 'select_word_meaning',
            school: 'あまりがわる数より大きいとき、どうしますか。',
            easy: '残りがまだ分けられる数のとき、どう考えますか。',
            choices: ['もう1つ作れるか考える', 'そのまま答える', 'かけ算をしない'],
            correct: 0,
            explanation: 'あまりがわる数以上なら、まだもう1つまとまりを作れます。',
            vocabulary: ['わる数より小さい'],
            tags: ['remainder_check', 'select_word_meaning'],
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_2_japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 12207,
            type: 'fill_blank',
            school: '23 ÷ 4 = 5 あまり□。□に入る数は何ですか。',
            easy: '4×5=20。23から20をひくといくつですか。',
            choices: ['2', '3', '4', '5'],
            correct: 1,
            explanation: '23-20=3 なので、23÷4=5 あまり3です。',
            vocabulary: ['あまり'],
            tags: ['remainder_calculation', 'fill_blank'],
            equationHint: '23 ÷ 4 = 5 あまり 3',
          ),
          _q(
            id: 12208,
            type: 'remainder_calculation',
            school: '34 ÷ 5 を計算しましょう。',
            easy: '34を5でわります。答えはどれですか。',
            choices: ['6 あまり 4', '7 あまり 1', '5 あまり 9'],
            correct: 0,
            explanation: '5×6=30、34-30=4 なので、6 あまり4です。',
            vocabulary: ['計算'],
            tags: ['remainder_calculation'],
            equationHint: '34 ÷ 5 = 6 あまり 4',
          ),
        ],
      ),
      _summary(
        id: 'grade3_remainder_2_summary',
        school: 'あまりは、いつもわる数より小さくします。',
        easy: 'あまりが大きすぎたら、もう1つまとまりを作れるか考えます。',
      ),
    ],
  ),
  Lesson(
    id: 14,
    levelId: 2,
    type: LessonType.practice,
    title: 'あまりのある文章題',
    description: '文章題から、式・商・あまり・単位を読み取ります。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'grade3_remainder_3_learn',
        title: '学習しよう',
        school: '文章題では、まずぜんぶの数を見つけます。次に、何こずつ分けるか、何人で分けるかを見つけます。最後に、式と単位を考えます。',
        easy: '文章を読んで、ぜんぶの数、分ける数、何を聞いているかを見ます。',
      ),
      _learn(
        id: 'grade3_remainder_3_words',
        title: 'ことばを知ろう',
        school: '大事な言葉は「何こずつ」「何人で」「何ふくろ」「何こあまり」「1人分」「同じ数ずつ」です。',
        easy: '答えの単位は、聞かれている言葉を見て選びます。',
      ),
      LessonStep(
        id: 'grade3_remainder_3_guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに解こう',
        questions: [
          _q(
            id: 12301,
            type: 'select_equation',
            school: '17このクッキーを5こずつふくろに入れます。式はどれですか。',
            easy: 'クッキー17こを、5こずつにします。どの式ですか。',
            choices: ['17÷5', '17×5', '17−5'],
            correct: 0,
            explanation: 'クッキー17こを5こずつにするので、17÷5です。',
            vocabulary: ['式', '何こずつ'],
            tags: ['story_to_equation', 'select_equation'],
            equationHint: '17 ÷ 5',
          ),
          _q(
            id: 12302,
            type: 'quotient_remainder_unit_choice',
            school: '17このクッキーを5こずつふくろに入れます。何ふくろできて、何こあまりますか。',
            easy: 'クッキー17こを5こずつにします。ふくろはいくつ、残りは何こですか。',
            choices: ['3ふくろ、2こ', '2ふくろ、3こ', '5ふくろ、2こ'],
            correct: 0,
            explanation: '17÷5=3 あまり2。3ふくろできて、2こあまります。',
            vocabulary: ['ふくろ', 'あまり'],
            tags: ['word_problem', 'quotient_remainder_unit_choice'],
            equationHint: '17 ÷ 5 = 3 あまり 2',
          ),
          _q(
            id: 12303,
            type: 'select_equation',
            school: '23このあめを4人で同じ数ずつ分けます。式はどれですか。',
            easy: 'あめ23こを4人で分けます。どの式ですか。',
            choices: ['23÷4', '23×4', '23＋4'],
            correct: 0,
            explanation: 'あめ23こを4人で分けるので、23÷4です。',
            vocabulary: ['同じ数ずつ', '式'],
            tags: ['word_problem', 'select_equation'],
            equationHint: '23 ÷ 4',
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_3_practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 12304,
            type: 'quotient_remainder_unit_choice',
            school: '23このあめを4人で分けます。1人分は何こで、何こあまりますか。',
            easy: 'あめ23こを4人で同じ数ずつ分けます。1人は何こ、残りは何こですか。',
            choices: ['5こ、3こ', '4こ、5こ', '6こ、1こ'],
            correct: 0,
            explanation: '23÷4=5 あまり3。1人分は5こで、3こあまります。',
            vocabulary: ['1人分', '何こあまり'],
            tags: ['word_problem', 'quotient_remainder_unit_choice'],
            equationHint: '23 ÷ 4 = 5 あまり 3',
          ),
          _q(
            id: 12305,
            type: 'unit_choice',
            school: '28本のえんぴつを5本ずつ束にします。商の単位はどれですか。',
            easy: '何束できるかを聞いています。答えの単位はどれですか。',
            choices: ['束', '本', '人'],
            correct: 0,
            explanation: 'できるまとまりの数を聞いているので、単位は束です。',
            vocabulary: ['商の単位', '束'],
            tags: ['unit_choice', 'unit'],
          ),
          _q(
            id: 12306,
            type: 'unit_choice',
            school: '28本のえんぴつを6人で分けます。あまりの単位はどれですか。',
            easy: '残るえんぴつの数を聞いています。単位はどれですか。',
            choices: ['本', '人', '束'],
            correct: 0,
            explanation: 'あまるものはえんぴつなので、単位は本です。',
            vocabulary: ['あまりの単位'],
            tags: ['unit_choice', 'unit'],
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_3_japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 12307,
            type: 'word_problem',
            school: '19まいのカードを1人に6まいずつ配ります。何人に配れて、何まいあまりますか。',
            easy: 'カード19まいを、1人に6まいずつ配ります。何人、残りは何まいですか。',
            choices: ['3人、1まい', '2人、7まい', '4人、1まい'],
            correct: 0,
            explanation: '19÷6=3 あまり1。3人に配れて、1まいあまります。',
            vocabulary: ['何人に配れる', 'まい'],
            tags: ['word_problem', 'quotient_remainder_unit_choice'],
            equationHint: '19 ÷ 6 = 3 あまり 1',
          ),
          _q(
            id: 12308,
            type: 'word_problem',
            school: '31このビー玉を7人で同じ数ずつ分けます。1人分は何こで、何こあまりますか。',
            easy: 'ビー玉31こを7人で分けます。1人は何こ、残りは何こですか。',
            choices: ['4こ、3こ', '3こ、4こ', '5こ、4こ'],
            correct: 0,
            explanation: '31÷7=4 あまり3。1人分は4こで、3こあまります。',
            vocabulary: ['1人分', 'あまり'],
            tags: ['word_problem', 'quotient_remainder_unit_choice'],
            equationHint: '31 ÷ 7 = 4 あまり 3',
          ),
        ],
      ),
      _summary(
        id: 'grade3_remainder_3_summary',
        school: '文章題では、式だけでなく、商とあまりの単位も確認します。',
        easy: '何を聞かれているかを見ると、答えの単位が分かります。',
      ),
    ],
  ),
  Lesson(
    id: 15,
    levelId: 2,
    type: LessonType.practice,
    title: 'あまりの考え方',
    description: 'あまりが出たとき、場面に合わせて答え方を考えます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'division-remainder-context-learn',
        title: '学習しよう',
        school: '4人がけの長いすがあります。9人がすわるには、長いすは3台いります。あまりが出たら、場面に合わせて答え方を考えます。',
        easy: 'あまりをどうするかは、問題の場面で決めます。',
      ),
      _learn(
        id: 'division-remainder-context-words',
        title: 'ことばを知ろう',
        school: 'このレッスンで使うことばは「必要」「1つ増やす」「使わない」「場面」です。',
        easy: 'あまりを答えにどう使うか考えるためのことばです。',
      ),
      LessonStep(
        id: 'grade3_remainder_4_guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに解こう',
        questions: [
          _q(
            id: 12401,
            type: 'remainder_usage_choice',
            school: '17このクッキーで、5こ入りの袋を作ります。いっぱいの袋は何袋できますか。',
            easy: '5こ入った袋を作ります。いっぱいの袋はいくつできますか。',
            questionTextRuby:
                '17このクッキーで、5こ{入|い}りの{袋|ふくろ}を{作|つく}ります。いっぱいの{袋|ふくろ}は{何袋|なんふくろ}できますか。',
            choicesRuby: ['3{袋|ふくろ}', '4{袋|ふくろ}', '2{袋|ふくろ}'],
            choices: ['3袋', '4袋', '2袋'],
            correct: 0,
            explanation: '17÷5=3 あまり2。5こ入りの袋は3袋できます。',
            explanationRuby: '17÷5=3 あまり2。5こ{入|い}りの{袋|ふくろ}は3{袋|ふくろ}できます。',
            vocabulary: ['袋', 'あまりを書く'],
            tags: ['remainder_usage_choice'],
            native: {
              AppLanguage.portuguese:
                  'Com 17 biscoitos, fazemos sacos com 5 biscoitos cada. Quantos sacos cheios conseguimos fazer?',
              AppLanguage.tagalog:
                  'Sa 17 biskwit, gumagawa tayo ng bag na tig-5. Ilang punong bag ang magagawa?',
              AppLanguage.vietnamese:
                  'Với 17 cái bánh, làm túi đựng 5 cái. Được bao nhiêu túi đầy?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  '17 ÷ 5 = 3, resto 2. Conseguimos fazer 3 sacos cheios.',
              AppLanguage.tagalog:
                  '17 ÷ 5 = 3, sobra 2. 3 punong bag ang nagawa.',
              AppLanguage.vietnamese:
                  '17 ÷ 5 = 3 dư 2. Làm được 3 túi đầy.',
            },
            equationHint: '17 ÷ 5 = 3 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: '🍪',
            itemUnit: 'こ',
            totalCount: 17,
            groupCount: 3,
            perGroupCount: 5,
            remainderCount: 2,
          ),
          _q(
            id: 12402,
            type: 'round_up_context',
            school: '17人が5人ずつ車に乗ります。車は何台必要ですか。',
            easy: '5人乗りの車に17人が乗ります。みんなが乗るには何台いりますか。',
            questionTextRuby:
                '17{人|にん}が5{人|にん}ずつ{車|くるま}に{乗|の}ります。{車|くるま}は{何台|なんだい}{必要|ひつよう}ですか。',
            choicesRuby: ['3{台|だい}', '4{台|だい}', '5{台|だい}'],
            choices: ['3台', '4台', '5台'],
            correct: 1,
            explanation: '17÷5=3 あまり2。2人が残るので、もう1台必要です。',
            explanationRuby:
                '17÷5=3 あまり2。2{人|にん}が{残|のこ}るので、もう1{台|だい}{必要|ひつよう}です。',
            vocabulary: ['必要', '1つ増やす'],
            tags: ['round_up_context'],
            native: {
              AppLanguage.portuguese:
                  '17 pessoas entram em carros com 5 pessoas em cada carro. Quantos carros são necessários?',
              AppLanguage.tagalog:
                  '17 tao ang sasakay sa kotse na tig-5. Ilang kotse ang kailangan?',
              AppLanguage.vietnamese:
                  '17 người lên xe 5 chỗ. Cần bao nhiêu xe?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  '17 ÷ 5 = 3, resto 2. Como ainda sobram 2 pessoas, é necessário mais 1 carro.',
              AppLanguage.tagalog:
                  '17 ÷ 5 = 3, sobra 2. Dahil 2 tao pa ang natira, kailangan pa ng 1 kotse.',
              AppLanguage.vietnamese:
                  '17 ÷ 5 = 3 dư 2. Còn 2 người nên cần thêm 1 xe.',
            },
            equationHint: '17 ÷ 5 = 3 あまり 2',
            thinkingHint: 'あまった人も乗る必要があります。',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: '👤',
            itemUnit: '人',
            totalCount: 17,
            groupCount: 3,
            perGroupCount: 5,
            remainderCount: 2,
          ),
          _q(
            id: 12403,
            type: 'ignore_remainder_context',
            school: '17cmのリボンを5cmずつ切ります。5cmのリボンは何本できますか。',
            easy: '17cmを5cmずつに切ります。5cmに足りない残りは数えません。',
            questionTextRuby: '17cmのリボンを5cmずつ{切|き}ります。5cmのリボンは{何本|なんぼん}できますか。',
            choicesRuby: ['3{本|ぼん}', '4{本|ほん}', '2{本|ほん}'],
            choices: ['3本', '4本', '2本'],
            correct: 0,
            explanation: '17÷5=3 あまり2。あまり2cmは5cmに足りないので、3本です。',
            explanationRuby: '17÷5=3 あまり2。あまり2cmは5cmに{足|た}りないので、3{本|ぼん}です。',
            vocabulary: ['足りない', '使わない'],
            tags: ['ignore_remainder_context'],
            native: {
              AppLanguage.portuguese:
                  'Cortamos uma fita de 17 cm em pedaços de 5 cm. Quantos pedaços de 5 cm conseguimos fazer?',
              AppLanguage.tagalog:
                  'Hatiin ang lasong 17 cm nang tig-5 cm. Ilang pirasong 5 cm ang magagawa?',
              AppLanguage.vietnamese:
                  'Cắt ruy-băng 17 cm thành đoạn 5 cm. Được bao nhiêu đoạn 5 cm?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  '17 ÷ 5 = 3, resto 2. Os 2 cm que sobram não chegam a 5 cm, então são 3 pedaços.',
              AppLanguage.tagalog:
                  '17 ÷ 5 = 3, sobra 2. Ang 2 cm ay kulang sa 5 cm, kaya 3 piraso.',
              AppLanguage.vietnamese:
                  '17 ÷ 5 = 3 dư 2. 2 cm không đủ 5 cm nên được 3 đoạn.',
            },
            equationHint: '17 ÷ 5 = 3 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: 'ribbon',
            itemUnit: 'cm',
            totalCount: 17,
            groupCount: 3,
            perGroupCount: 5,
            remainderCount: 2,
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_4_practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 12404,
            type: 'round_up_context',
            school: '22人が4人ずつ車に乗るなら、車は何台必要ですか。',
            easy: '4人乗りの車に22人が乗ります。みんなが乗るには何台いりますか。',
            questionTextRuby:
                '22{人|にん}が4{人|にん}ずつ{車|くるま}に{乗|の}るなら、{車|くるま}は{何台|なんだい}{必要|ひつよう}ですか。',
            choicesRuby: ['5{台|だい}', '6{台|だい}', '7{台|だい}'],
            choices: ['5台', '6台', '7台'],
            correct: 1,
            explanation: '22÷4=5 あまり2。2人が残るので、もう1台必要です。',
            explanationRuby:
                '22÷4=5 あまり2。2{人|にん}が{残|のこ}るので、もう1{台|だい}{必要|ひつよう}です。',
            vocabulary: ['必要', '1つ増やす'],
            tags: ['round_up_context'],
            native: {
              AppLanguage.portuguese:
                  'Se 22 pessoas entram em carros com 4 pessoas em cada carro, quantos carros são necessários?',
              AppLanguage.tagalog:
                  'Kung 22 tao ang sasakay sa kotse na tig-4, ilang kotse ang kailangan?',
              AppLanguage.vietnamese:
                  'Nếu 22 người lên xe 4 chỗ thì cần bao nhiêu xe?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  '22 ÷ 4 = 5, resto 2. Como ainda sobram 2 pessoas, é necessário mais 1 carro.',
              AppLanguage.tagalog:
                  '22 ÷ 4 = 5, sobra 2. Dahil 2 tao pa ang natira, kailangan pa ng 1 kotse.',
              AppLanguage.vietnamese:
                  '22 ÷ 4 = 5 dư 2. Còn 2 người nên cần thêm 1 xe.',
            },
            equationHint: '22 ÷ 4 = 5 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: '👤',
            itemUnit: '人',
            totalCount: 22,
            groupCount: 5,
            perGroupCount: 4,
            remainderCount: 2,
          ),
          _q(
            id: 12405,
            type: 'remainder_usage_choice',
            school: '22このりんごで、4こ入りの袋を作ります。いっぱいの袋は何袋できますか。',
            easy: '4こ入った袋を作ります。いっぱいの袋はいくつできますか。',
            questionTextRuby:
                '22このりんごで、4こ{入|い}りの{袋|ふくろ}を{作|つく}ります。いっぱいの{袋|ふくろ}は{何袋|なんふくろ}できますか。',
            choicesRuby: ['5{袋|ふくろ}', '6{袋|ふくろ}', '4{袋|ふくろ}'],
            choices: ['5袋', '6袋', '4袋'],
            correct: 0,
            explanation: '22÷4=5 あまり2。4こ入りの袋は5袋できます。',
            explanationRuby: '22÷4=5 あまり2。4こ{入|い}りの{袋|ふくろ}は5{袋|ふくろ}できます。',
            vocabulary: ['袋', 'あまりを書く'],
            tags: ['remainder_usage_choice'],
            native: {
              AppLanguage.portuguese:
                  'Com 22 maçãs, fazemos sacos com 4 maçãs cada. Quantos sacos cheios conseguimos fazer?',
              AppLanguage.tagalog:
                  'Sa 22 mansanas, gumagawa tayo ng bag na tig-4. Ilang punong bag ang magagawa?',
              AppLanguage.vietnamese:
                  'Với 22 quả táo, làm túi đựng 4 quả. Được bao nhiêu túi đầy?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  '22 ÷ 4 = 5, resto 2. Conseguimos fazer 5 sacos cheios.',
              AppLanguage.tagalog:
                  '22 ÷ 4 = 5, sobra 2. 5 punong bag ang nagawa.',
              AppLanguage.vietnamese:
                  '22 ÷ 4 = 5 dư 2. Làm được 5 túi đầy.',
            },
            equationHint: '22 ÷ 4 = 5 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: '🍎',
            itemUnit: 'こ',
            totalCount: 22,
            groupCount: 5,
            perGroupCount: 4,
            remainderCount: 2,
          ),
          _q(
            id: 12406,
            type: 'ignore_remainder_context',
            school: '22cmのひもを5cmずつ切るなら、5cmのひもは何本できますか。',
            easy: '5cmに足りない残りは数えません。何本できますか。',
            questionTextRuby: '22cmのひもを5cmずつ{切|き}るなら、5cmのひもは{何本|なんぼん}できますか。',
            choicesRuby: ['4{本|ほん}', '5{本|ほん}', '2{本|ほん}'],
            choices: ['4本', '5本', '2本'],
            correct: 0,
            explanation: '22÷5=4 あまり2。あまり2cmは5cmに足りないので、4本です。',
            explanationRuby: '22÷5=4 あまり2。あまり2cmは5cmに{足|た}りないので、4{本|ほん}です。',
            vocabulary: ['足りない', '本'],
            tags: ['ignore_remainder_context'],
            native: {
              AppLanguage.portuguese:
                  'Cortamos uma corda de 22 cm em pedaços de 5 cm. Quantos pedaços de 5 cm conseguimos fazer?',
              AppLanguage.tagalog:
                  'Hatiin ang lubid na 22 cm nang tig-5 cm. Ilang pirasong 5 cm ang magagawa?',
              AppLanguage.vietnamese:
                  'Cắt dây 22 cm thành đoạn 5 cm. Được bao nhiêu đoạn 5 cm?',
            },
            nativeExplanation: {
              AppLanguage.portuguese:
                  '22 ÷ 5 = 4, resto 2. Os 2 cm que sobram não chegam a 5 cm, então são 4 pedaços.',
              AppLanguage.tagalog:
                  '22 ÷ 5 = 4, sobra 2. Ang 2 cm ay kulang sa 5 cm, kaya 4 piraso.',
              AppLanguage.vietnamese:
                  '22 ÷ 5 = 4 dư 2. 2 cm không đủ 5 cm nên được 4 đoạn.',
            },
            equationHint: '22 ÷ 5 = 4 あまり 2',
            visualType: QuestionVisualType.divisionRemainder,
            itemEmoji: 'rope',
            itemUnit: 'cm',
            totalCount: 22,
            groupCount: 4,
            perGroupCount: 5,
            remainderCount: 2,
          ),
        ],
      ),
      LessonStep(
        id: 'grade3_remainder_4_japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 12407,
            type: 'select_word_meaning',
            school: '車が6台必要な理由はどれですか。',
            easy: 'なぜ車を1台増やしますか。',
            choices: ['あまった人も乗るから', 'あまりを使わないから', '車は5台でよいから'],
            correct: 0,
            explanation: 'あまった人も乗る必要があるので、車を1台増やします。',
            vocabulary: ['理由', '必要'],
            tags: ['round_up_context', 'select_word_meaning'],
          ),
          _q(
            id: 12408,
            type: 'select_word_meaning',
            school: 'リボンが3本だけできる理由はどれですか。',
            easy: 'なぜあまりのリボンを数えませんか。',
            choices: ['あまりは5cmに足りないから', 'あまったリボンも1本にするから', 'わり算を使わないから'],
            correct: 0,
            explanation: 'あまりは5cmに足りないので、5cmのリボンとして数えません。',
            vocabulary: ['足りない', '理由'],
            tags: ['ignore_remainder_context', 'select_word_meaning'],
          ),
        ],
      ),
      _summary(
        id: 'grade3_remainder_4_summary',
        school: 'あまりは、場面によって「書く」「1つ増やす」「使わない」を選びます。',
        easy: '文章の意味を見て、あまりをどうするか決めます。',
        native: {
          AppLanguage.portuguese:
              'Quando aparece resto, decidimos o que fazer olhando a situação do problema.',
          AppLanguage.tagalog:
              'Kapag may sobra, tinitingnan ang sitwasyon ng problema para magpasya.',
          AppLanguage.vietnamese:
              'Khi có số dư, ta nhìn tình huống bài toán để quyết định.',
        },
      ),
    ],
  ),
  Lesson(
    id: 16,
    levelId: 2,
    type: LessonType.practice,
    title: 'たしかめ問題',
    description: '',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      LessonStep(
        id: 'grade3_remainder_check',
        type: LessonStepType.independentPractice,
        title: 'たしかめ問題',
        questions: [
          _q(
            id: 12501,
            type: 'remainder_calculation',
            school: '19このあめを6こずつ分けます。あまりはいくつですか。',
            easy: 'あめ19こを6こずつにします。あまりはいくつですか。',
            choices: ['1', '2', '7'],
            correct: 0,
            explanation: 'あめを6こずつ分けると、3組できて、1こ残ります。',
            explanationRuby:
                'あめを6こずつ{分|わ}けると、3{組|くみ}できて、1こ{残|のこ}ります。',
            vocabulary: ['計算'],
            tags: ['remainder_calculation'],
            equationHint: '19 ÷ 6 = 3 あまり 1',
          ),
          _q(
            id: 12502,
            type: 'select_equation',
            school: '34このクッキーを5こずつ分けます。式はどれですか。',
            easy: 'クッキー34こを5こずつにします。どの式ですか。',
            choices: ['34÷5', '34×5', '34−5'],
            correct: 0,
            explanation: '全部の34このクッキーを、5こずつ分けるので、式は34÷5です。',
            explanationRuby:
                '{全部|ぜんぶ}の34このクッキーを、5こずつ{分|わ}けるので、{式|しき}は34÷5です。',
            vocabulary: ['式'],
            tags: ['select_equation', 'remainder_calculation'],
            equationHint: '34 ÷ 5 = 6 あまり 4',
          ),
          _q(
            id: 12503,
            type: 'unit_choice',
            school: '29人が6人ずつ車に乗ります。答えの単位はどれですか。',
            easy: '車が何台必要かを聞いています。単位はどれですか。',
            choices: ['台', '人', '本'],
            correct: 0,
            explanation: '車の数を聞いているので、単位は台です。',
            explanationRuby: '{車|くるま}の{数|かず}を{聞|き}いているので、{単位|たんい}は{台|だい}です。',
            vocabulary: ['単位', '台'],
            tags: ['unit_choice', 'round_up_context'],
          ),
          _q(
            id: 12504,
            type: 'round_up_context',
            school: '29人が6人ずつ車に乗ります。車は何台必要ですか。',
            easy: '6人乗りの車に29人が乗ります。みんなが乗るには何台いりますか。',
            choices: ['4台', '5台', '6台'],
            correct: 1,
            explanation: '29÷6=4 あまり5。5人が残るので、車は5台必要です。',
            explanationRuby:
                '29÷6=4 あまり5。5{人|にん}が{残|のこ}るので、{車|くるま}は5{台|だい}{必要|ひつよう}です。',
            vocabulary: ['必要', '1つ増やす'],
            tags: ['round_up_context'],
            equationHint: '29 ÷ 6 = 4 あまり 5',
          ),
          _q(
            id: 12505,
            type: 'ignore_remainder_context',
            school: '29cmのひもを6cmずつ切ります。6cmのひもは何本できますか。',
            easy: '6cmに足りない残りは数えません。何本できますか。',
            choices: ['4本', '5本', '6本'],
            correct: 0,
            explanation: '29÷6=4 あまり5。あまり5cmは6cmに足りないので、4本です。',
            explanationRuby: '29÷6=4 あまり5。あまり5cmは6cmに{足|た}りないので、4{本|ほん}です。',
            vocabulary: ['足りない', '使わない'],
            tags: ['ignore_remainder_context'],
            equationHint: '29 ÷ 6 = 4 あまり 5',
          ),
          _q(
            id: 12506,
            type: 'remainder_usage_choice',
            school: '29このクッキーを6こずつ袋に入れます。いっぱいの袋は何袋できますか。',
            easy: '6こ入りの袋を作ります。いっぱいの袋はいくつできますか。',
            choices: ['4袋', '5袋', '6袋'],
            correct: 0,
            explanation: '29÷6=4 あまり5。6こ入りの袋は4袋できます。',
            explanationRuby: '29÷6=4 あまり5。6こ{入|い}りの{袋|ふくろ}は4{袋|ふくろ}できます。',
            vocabulary: ['袋', 'あまりを書く'],
            tags: ['remainder_usage_choice'],
            equationHint: '29 ÷ 6 = 4 あまり 5',
          ),
          _q(
            id: 12507,
            type: 'select_word_meaning',
            school: '車の問題で、あまりがあるときに1台増やすのはなぜですか。',
            easy: 'なぜ車をもう1台用意しますか。',
            choices: ['あまった人も乗る必要があるから', 'あまりを数えないから', '車はいつも1台だから'],
            correct: 0,
            explanation: 'あまった人も乗る必要があるので、車を1台増やします。',
            explanationRuby:
                'あまった{人|ひと}も{乗|の}る{必要|ひつよう}があるので、{車|くるま}を1{台|だい}{増|ふ}やします。',
            vocabulary: ['理由', '必要'],
            tags: ['round_up_context', 'select_word_meaning'],
          ),
          _q(
            id: 12508,
            type: 'select_word_meaning',
            school: 'ひもの問題で、あまりを数えないのはなぜですか。',
            easy: 'なぜ短い残りを1本にしませんか。',
            choices: ['必要な長さに足りないから', 'あまりがあるから1本増やすから', 'ひもはわり算できないから'],
            correct: 0,
            explanation: 'あまりは必要な長さに足りないので、1本として数えません。',
            explanationRuby:
                'あまりは{必要|ひつよう}な{長|なが}さに{足|た}りないので、1{本|ぽん}として{数|かぞ}えません。',
            vocabulary: ['足りない', '理由'],
            tags: ['ignore_remainder_context', 'select_word_meaning'],
          ),
          _q(
            id: 12509,
            type: 'round_up_context',
            school: '38人が5人ずつグループになります。全員が入るには、グループはいくつ必要ですか。',
            easy: '5人ずつのグループに38人が入ります。残った人も入るには、何グループ必要ですか。',
            choices: ['7グループ', '8グループ', '9グループ'],
            correct: 1,
            explanation: '38÷5=7 あまり3。3人が残るので、もう1グループ必要です。',
            explanationRuby:
                '38÷5=7 あまり3。3{人|にん}が{残|のこ}るので、もう1グループ{必要|ひつよう}です。',
            vocabulary: ['全員', 'グループ'],
            tags: ['round_up_context', 'word_problem'],
            equationHint: '38 ÷ 5 = 7 あまり 3',
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
}) {
  return LessonStep(
    id: id,
    type: LessonStepType.learn,
    title: title,
    explanationSchoolJa: school,
    explanationEasyJa: easy,
    explanationNative: _nativeText(easy),
  );
}

LessonStep _summary({
  required String id,
  required String school,
  required String easy,
  Map<AppLanguage, String> native = const {},
}) {
  return LessonStep(
    id: id,
    type: LessonStepType.summary,
    title: 'まとめ',
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
  required List<String> vocabulary,
  required List<String> tags,
  Map<AppLanguage, String> native = const {},
  Map<AppLanguage, String> nativeExplanation = const {},
  String correctAnswerText = '',
  String correctAnswerTextRuby = '',
  String questionTextRuby = '',
  List<String> choicesRuby = const [],
  String formulaExplanation = '',
  String formulaExplanationRuby = '',
  String languagePoint = '',
  String languagePointRuby = '',
  String explanationRuby = '',
  List<VocabularyEntry> vocabularyEntries = const [],
  QuestionVisualType visualType = QuestionVisualType.none,
  String visualTitle = '',
  String visualDescription = '',
  String itemLabel = '',
  String itemEmoji = '●',
  String itemUnit = 'こ',
  int? totalCount,
  int? groupCount,
  int? perGroupCount,
  int? remainderCount,
  String equationHint = '',
  String thinkingHint = '',
  String visualHint = '',
}) {
  return Question(
    id: id,
    type: type,
    unitId: 'grade3_division_remainder',
    promptSchoolJa: school,
    promptEasyJa: easy,
    promptNative: native.isNotEmpty ? native : _nativeText(easy),
    choices: choices,
    questionTextRuby: questionTextRuby,
    choicesRuby: choicesRuby,
    correctAnswer: correct,
    correctAnswerText: correctAnswerText,
    correctAnswerTextRuby: correctAnswerTextRuby,
    explanationEasyJa: explanation,
    explanation: explanation,
    explanationRuby: explanationRuby,
    formulaExplanation: formulaExplanation,
    formulaExplanationRuby: formulaExplanationRuby,
    languagePoint: languagePoint,
    languagePointRuby: languagePointRuby,
    vocabularyEntries: vocabularyEntries,
    explanationNative: nativeExplanation.isNotEmpty
        ? nativeExplanation
        : _nativeText(explanation),
    tags: ['grade3', 'math', 'division', 'remainder', ...tags],
    equationHint: equationHint,
    thinkingHint: thinkingHint,
    visualHint: visualHint,
    visualType: visualType,
    visualTitle: visualTitle,
    visualDescription: visualDescription,
    itemLabel: itemLabel,
    itemEmoji: itemEmoji,
    itemUnit: itemUnit,
    totalCount: totalCount,
    groupCount: groupCount,
    perGroupCount: perGroupCount,
    remainderCount: remainderCount,
    pictureDescription: visualHint,
    diagramType: visualHint.isEmpty ? '' : 'text_diagram',
    vocabulary: vocabulary,
    grade: 3,
    subject: 'math',
    unit: 'division_remainder',
  );
}

const _remainderVocabulary = [
  VocabularyEntry(
    term: '同じ数ずつ',
    reading: 'おなじかずずつ',
    simpleJapanese: 'ひとりひとりに、同じ数を配ること。',
    translations: {
      AppLanguage.portuguese: 'a mesma quantidade para cada pessoa',
      AppLanguage.tagalog: 'pare-parehong dami para sa bawat tao',
      AppLanguage.vietnamese: 'cùng một số lượng cho mỗi người',
    },
    exampleSentence: '4人に同じ数ずつ分けます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '分ける',
    reading: 'わける',
    simpleJapanese: 'ものを、何人かに配ること。',
    translations: {
      AppLanguage.portuguese: 'dividir / distribuir',
      AppLanguage.tagalog: 'hatiin / ipamahagi',
      AppLanguage.vietnamese: 'chia / phân phát',
    },
    exampleSentence: '13このあめを4人に分けます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '残る',
    reading: 'のこる',
    simpleJapanese: '使ったあと、まだあること。',
    translations: {
      AppLanguage.portuguese: 'restar / ficar',
      AppLanguage.tagalog: 'matira',
      AppLanguage.vietnamese: 'còn lại',
    },
    exampleSentence: '分けたあとに1こ残ります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '余る',
    reading: 'あまる',
    simpleJapanese: '分けたあとに、残ること。',
    translations: {
      AppLanguage.portuguese: 'sobrar',
      AppLanguage.tagalog: 'may matira',
      AppLanguage.vietnamese: 'còn dư',
    },
    exampleSentence: '1こ余ります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '答え',
    reading: 'こたえ',
    simpleJapanese: '問題で聞かれていることへの返事。',
    translations: {
      AppLanguage.portuguese: 'resposta',
      AppLanguage.tagalog: 'sagot',
      AppLanguage.vietnamese: 'đáp án',
    },
    exampleSentence: '答えは3あまり1です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '何こ',
    reading: 'なんこ',
    simpleJapanese: '数を聞く言葉。',
    translations: {
      AppLanguage.portuguese: 'quantos itens',
      AppLanguage.tagalog: 'ilang piraso',
      AppLanguage.vietnamese: 'bao nhiêu cái',
    },
    exampleSentence: '何こ余りますか。',
    category: 'math_language',
  ),
];

Map<AppLanguage, String> _nativeText(String fallback) {
  return switch (fallback) {
    '13-12=1 なので、13÷4=3 あまり1です。' => {
      AppLanguage.portuguese: 'Como 13 − 12 = 1, então 13 ÷ 4 = 3 resto 1.',
      AppLanguage.tagalog: 'Dahil 13 − 12 = 1, kaya 13 ÷ 4 = 3 sobra 1.',
      AppLanguage.vietnamese: 'Vì 13 − 12 = 1 nên 13 ÷ 4 = 3 dư 1.',
    },
    '13を4でわります。4×3=12。残りはいくつですか。' => {
      AppLanguage.portuguese: 'Dividimos 13 por 4. 4 × 3 = 12. Quanto sobra?',
      AppLanguage.tagalog: 'Hatiin ang 13 sa 4. 4 × 3 = 12. Ilan ang natira?',
      AppLanguage.vietnamese: 'Chia 13 cho 4. 4 × 3 = 12. Còn lại bao nhiêu?',
    },
    '14を3でわります。答えはどれですか。' => {
      AppLanguage.portuguese: 'Dividimos 14 por 3. Qual é a resposta?',
      AppLanguage.tagalog: 'Hatiin ang 14 sa 3. Ano ang sagot?',
      AppLanguage.vietnamese: 'Chia 14 cho 3. Đáp án nào đúng?',
    },
    '17cmを5cmずつに切ります。5cmに足りない残りは数えません。' => {
      AppLanguage.portuguese: 'Cortamos 17 cm de 5 em 5 cm. O resto menor que 5 cm não conta.',
      AppLanguage.tagalog: 'Hatiin ang 17 cm nang tig-5 cm. Hindi binibilang ang natirang kulang sa 5 cm.',
      AppLanguage.vietnamese: 'Cắt 17 cm thành từng đoạn 5 cm. Phần còn lại không đủ 5 cm thì không tính.',
    },
    '17÷5=3 あまり2。2人が残るので、もう1台必要です。' => {
      AppLanguage.portuguese: '17 ÷ 5 = 3 resto 2. Como 2 pessoas sobram, precisamos de mais 1 carro.',
      AppLanguage.tagalog: '17 ÷ 5 = 3 sobra 2. Dahil 2 tao ang natira, kailangan pa ng 1 kotse.',
      AppLanguage.vietnamese: '17 ÷ 5 = 3 dư 2. Còn 2 người nên cần thêm 1 xe.',
    },
    '17÷5=3 あまり2。3ふくろできて、2こあまります。' => {
      AppLanguage.portuguese: '17 ÷ 5 = 3 resto 2. Dá para 3 sacos e sobram 2.',
      AppLanguage.tagalog: '17 ÷ 5 = 3 sobra 2. 3 bag ang magagawa at 2 ang matitira.',
      AppLanguage.vietnamese: '17 ÷ 5 = 3 dư 2. Làm được 3 túi và còn 2.',
    },
    '17÷5=3 あまり2。5こ入りの袋は3袋できます。' => {
      AppLanguage.portuguese: '17 ÷ 5 = 3 resto 2. Dá para 3 sacos de 5.',
      AppLanguage.tagalog: '17 ÷ 5 = 3 sobra 2. 3 bag na tig-5 ang magagawa.',
      AppLanguage.vietnamese: '17 ÷ 5 = 3 dư 2. Làm được 3 túi loại 5 cái.',
    },
    '17÷5=3 あまり2。あまり2cmは5cmに足りないので、3本です。' => {
      AppLanguage.portuguese: '17 ÷ 5 = 3 resto 2. Os 2 cm não chegam a 5 cm, então são 3 pedaços.',
      AppLanguage.tagalog: '17 ÷ 5 = 3 sobra 2. Ang 2 cm ay kulang sa 5 cm, kaya 3 piraso.',
      AppLanguage.vietnamese: '17 ÷ 5 = 3 dư 2. 2 cm không đủ 5 cm nên được 3 đoạn.',
    },
    '17を5でわると、3こずつ作れて、何こ残りますか。' => {
      AppLanguage.portuguese: 'Ao dividir 17 por 5, formamos grupos de 3. Quantos sobram?',
      AppLanguage.tagalog: 'Kung hatiin ang 17 sa 5, makakagawa ng tig-3. Ilan ang matitira?',
      AppLanguage.vietnamese: 'Chia 17 cho 5 thì làm được nhóm 3. Còn lại bao nhiêu?',
    },
    '19÷6=3 あまり1。3人に配れて、1まいあまります。' => {
      AppLanguage.portuguese: '19 ÷ 6 = 3 resto 1. Dá para 3 pessoas e sobra 1 carta.',
      AppLanguage.tagalog: '19 ÷ 6 = 3 sobra 1. Naipamahagi sa 3 tao at 1 ang natira.',
      AppLanguage.vietnamese: '19 ÷ 6 = 3 dư 1. Phát được cho 3 người và còn 1 tấm.',
    },
    '20を6でわります。答えはどれですか。' => {
      AppLanguage.portuguese: 'Dividimos 20 por 6. Qual é a resposta?',
      AppLanguage.tagalog: 'Hatiin ang 20 sa 6. Ano ang sagot?',
      AppLanguage.vietnamese: 'Chia 20 cho 6. Đáp án nào đúng?',
    },
    '22÷4=5 あまり2。2人が残るので、もう1台必要です。' => {
      AppLanguage.portuguese: '22 ÷ 4 = 5 resto 2. Como 2 pessoas sobram, precisamos de mais 1 carro.',
      AppLanguage.tagalog: '22 ÷ 4 = 5 sobra 2. Dahil 2 tao ang natira, kailangan pa ng 1 kotse.',
      AppLanguage.vietnamese: '22 ÷ 4 = 5 dư 2. Còn 2 người nên cần thêm 1 xe.',
    },
    '22÷4=5 あまり2。4こ入りの袋は5袋できます。' => {
      AppLanguage.portuguese: '22 ÷ 4 = 5 resto 2. Dá para 5 sacos de 4.',
      AppLanguage.tagalog: '22 ÷ 4 = 5 sobra 2. 5 bag na tig-4 ang magagawa.',
      AppLanguage.vietnamese: '22 ÷ 4 = 5 dư 2. Làm được 5 túi loại 4 cái.',
    },
    '22÷5=4 あまり2。あまり2cmは5cmに足りないので、4本です。' => {
      AppLanguage.portuguese: '22 ÷ 5 = 4 resto 2. Os 2 cm não chegam a 5 cm, então são 4 pedaços.',
      AppLanguage.tagalog: '22 ÷ 5 = 4 sobra 2. Ang 2 cm ay kulang sa 5 cm, kaya 4 piraso.',
      AppLanguage.vietnamese: '22 ÷ 5 = 4 dư 2. 2 cm không đủ 5 cm nên được 4 đoạn.',
    },
    '23-20=3 なので、23÷4=5 あまり3です。' => {
      AppLanguage.portuguese: 'Como 23 − 20 = 3, então 23 ÷ 4 = 5 resto 3.',
      AppLanguage.tagalog: 'Dahil 23 − 20 = 3, kaya 23 ÷ 4 = 5 sobra 3.',
      AppLanguage.vietnamese: 'Vì 23 − 20 = 3 nên 23 ÷ 4 = 5 dư 3.',
    },
    '23÷4=5 あまり3。1人分は5こで、3こあまります。' => {
      AppLanguage.portuguese: '23 ÷ 4 = 5 resto 3. Cada pessoa recebe 5 e sobram 3.',
      AppLanguage.tagalog: '23 ÷ 4 = 5 sobra 3. 5 ang sa bawat isa at 3 ang natira.',
      AppLanguage.vietnamese: '23 ÷ 4 = 5 dư 3. Mỗi người được 5, còn 3.',
    },
    '29÷6=4 あまり5。5人が残るので、車は5台必要です。' => {
      AppLanguage.portuguese: '29 ÷ 6 = 4 resto 5. Como 5 pessoas sobram, precisamos de 5 carros.',
      AppLanguage.tagalog: '29 ÷ 6 = 4 sobra 5. Dahil 5 tao ang natira, 5 kotse ang kailangan.',
      AppLanguage.vietnamese: '29 ÷ 6 = 4 dư 5. Còn 5 người nên cần 5 xe.',
    },
    '29÷6=4 あまり5。6こ入りの袋は4袋できます。' => {
      AppLanguage.portuguese: '29 ÷ 6 = 4 resto 5. Dá para 4 sacos de 6.',
      AppLanguage.tagalog: '29 ÷ 6 = 4 sobra 5. 4 bag na tig-6 ang magagawa.',
      AppLanguage.vietnamese: '29 ÷ 6 = 4 dư 5. Làm được 4 túi loại 6 cái.',
    },
    '29÷6=4 あまり5。あまり5cmは6cmに足りないので、4本です。' => {
      AppLanguage.portuguese: '29 ÷ 6 = 4 resto 5. Os 5 cm não chegam a 6 cm, então são 4 pedaços.',
      AppLanguage.tagalog: '29 ÷ 6 = 4 sobra 5. Ang 5 cm ay kulang sa 6 cm, kaya 4 piraso.',
      AppLanguage.vietnamese: '29 ÷ 6 = 4 dư 5. 5 cm không đủ 6 cm nên được 4 đoạn.',
    },
    '2こずつのまとまりが2つできて、1こ残ります。' => {
      AppLanguage.portuguese: 'Formamos 2 grupos de 2 e sobra 1.',
      AppLanguage.tagalog: '2 grupong tig-2 ang nagawa at 1 ang natira.',
      AppLanguage.vietnamese: 'Làm được 2 nhóm 2 cái và còn 1.',
    },
    '31÷7=4 あまり3。1人分は4こで、3こあまります。' => {
      AppLanguage.portuguese: '31 ÷ 7 = 4 resto 3. Cada pessoa recebe 4 e sobram 3.',
      AppLanguage.tagalog: '31 ÷ 7 = 4 sobra 3. 4 ang sa bawat isa at 3 ang natira.',
      AppLanguage.vietnamese: '31 ÷ 7 = 4 dư 3. Mỗi người được 4, còn 3.',
    },
    '34を5でわります。答えはどれですか。' => {
      AppLanguage.portuguese: 'Dividimos 34 por 5. Qual é a resposta?',
      AppLanguage.tagalog: 'Hatiin ang 34 sa 5. Ano ang sagot?',
      AppLanguage.vietnamese: 'Chia 34 cho 5. Đáp án nào đúng?',
    },
    '38÷5=7 あまり3。3人が残るので、もう1グループ必要です。' => {
      AppLanguage.portuguese: '38 ÷ 5 = 7 resto 3. Como 3 pessoas sobram, precisamos de mais 1 grupo.',
      AppLanguage.tagalog: '38 ÷ 5 = 7 sobra 3. Dahil 3 tao ang natira, kailangan pa ng 1 grupo.',
      AppLanguage.vietnamese: '38 ÷ 5 = 7 dư 3. Còn 3 người nên cần thêm 1 nhóm.',
    },
    '3×4=12、14-12=2 なので、4 あまり2です。' => {
      AppLanguage.portuguese: 'Como 3 × 4 = 12 e 14 − 12 = 2, a resposta é 4 resto 2.',
      AppLanguage.tagalog: 'Dahil 3 × 4 = 12 at 14 − 12 = 2, ang sagot ay 4 sobra 2.',
      AppLanguage.vietnamese: 'Vì 3 × 4 = 12 và 14 − 12 = 2 nên đáp án là 4 dư 2.',
    },
    '4×5=20。23から20をひくといくつですか。' => {
      AppLanguage.portuguese: '4 × 5 = 20. Quanto é 23 menos 20?',
      AppLanguage.tagalog: '4 × 5 = 20. Magkano ang 23 minus 20?',
      AppLanguage.vietnamese: '4 × 5 = 20. 23 trừ 20 bằng bao nhiêu?',
    },
    '4こずつのまとまりが2つできて、2こ残ります。' => {
      AppLanguage.portuguese: 'Formamos 2 grupos de 4 e sobram 2.',
      AppLanguage.tagalog: '2 grupong tig-4 ang nagawa at 2 ang natira.',
      AppLanguage.vietnamese: 'Làm được 2 nhóm 4 cái và còn 2.',
    },
    '4こ入った袋を作ります。いっぱいの袋はいくつできますか。' => {
      AppLanguage.portuguese: 'Fazemos sacos de 4. Quantos sacos cheios dá para fazer?',
      AppLanguage.tagalog: 'Gumagawa tayo ng bag na tig-4. Ilang punong bag ang magagawa?',
      AppLanguage.vietnamese: 'Làm túi đựng 4 cái. Được bao nhiêu túi đầy?',
    },
    '4人乗りの車に22人が乗ります。みんなが乗るには何台いりますか。' => {
      AppLanguage.portuguese: 'Um carro leva 4 pessoas e há 22 pessoas. Quantos carros precisamos para todos?',
      AppLanguage.tagalog: '4 tao ang kasya sa isang kotse at 22 ang tao. Ilang kotse para masakyan lahat?',
      AppLanguage.vietnamese: 'Xe 4 chỗ, có 22 người. Cần bao nhiêu xe để mọi người lên?',
    },
    '5cmに足りない残りは数えません。何本できますか。' => {
      AppLanguage.portuguese: 'O resto menor que 5 cm não conta. Quantos pedaços dá para fazer?',
      AppLanguage.tagalog: 'Hindi binibilang ang natirang kulang sa 5 cm. Ilang piraso ang magagawa?',
      AppLanguage.vietnamese: 'Phần còn lại không đủ 5 cm thì không tính. Được bao nhiêu đoạn?',
    },
    '5×3=15、17-15=2 なので、あまりは2です。' => {
      AppLanguage.portuguese: 'Como 5 × 3 = 15 e 17 − 15 = 2, o resto é 2.',
      AppLanguage.tagalog: 'Dahil 5 × 3 = 15 at 17 − 15 = 2, ang sobra ay 2.',
      AppLanguage.vietnamese: 'Vì 5 × 3 = 15 và 17 − 15 = 2 nên số dư là 2.',
    },
    '5×6=30、34-30=4 なので、6 あまり4です。' => {
      AppLanguage.portuguese: 'Como 5 × 6 = 30 e 34 − 30 = 4, a resposta é 6 resto 4.',
      AppLanguage.tagalog: 'Dahil 5 × 6 = 30 at 34 − 30 = 4, ang sagot ay 6 sobra 4.',
      AppLanguage.vietnamese: 'Vì 5 × 6 = 30 và 34 − 30 = 4 nên đáp án là 6 dư 4.',
    },
    '5こずつのまとまりが2つできて、3こ残ります。' => {
      AppLanguage.portuguese: 'Formamos 2 grupos de 5 e sobram 3.',
      AppLanguage.tagalog: '2 grupong tig-5 ang nagawa at 3 ang natira.',
      AppLanguage.vietnamese: 'Làm được 2 nhóm 5 cái và còn 3.',
    },
    '5こ入った袋を作ります。いっぱいの袋はいくつできますか。' => {
      AppLanguage.portuguese: 'Fazemos sacos de 5. Quantos sacos cheios dá para fazer?',
      AppLanguage.tagalog: 'Gumagawa tayo ng bag na tig-5. Ilang punong bag ang magagawa?',
      AppLanguage.vietnamese: 'Làm túi đựng 5 cái. Được bao nhiêu túi đầy?',
    },
    '5人ずつのグループに38人が入ります。残った人も入るには、何グループ必要ですか。' => {
      AppLanguage.portuguese: 'Grupos de 5 pessoas para 38 pessoas. Quantos grupos precisamos para incluir quem sobrou?',
      AppLanguage.tagalog: 'Grupo-grupo ng tig-5 para sa 38 tao. Ilang grupo para maisama ang natira?',
      AppLanguage.vietnamese: 'Nhóm 5 người cho 38 người. Cần bao nhiêu nhóm để người còn lại cũng vào?',
    },
    '5人乗りの車に17人が乗ります。みんなが乗るには何台いりますか。' => {
      AppLanguage.portuguese: 'Um carro leva 5 pessoas e há 17 pessoas. Quantos carros precisamos para todos?',
      AppLanguage.tagalog: '5 tao ang kasya sa isang kotse at 17 ang tao. Ilang kotse para masakyan lahat?',
      AppLanguage.vietnamese: 'Xe 5 chỗ, có 17 người. Cần bao nhiêu xe để mọi người lên?',
    },
    '6cmに足りない残りは数えません。何本できますか。' => {
      AppLanguage.portuguese: 'O resto menor que 6 cm não conta. Quantos pedaços dá para fazer?',
      AppLanguage.tagalog: 'Hindi binibilang ang natirang kulang sa 6 cm. Ilang piraso ang magagawa?',
      AppLanguage.vietnamese: 'Phần còn lại không đủ 6 cm thì không tính. Được bao nhiêu đoạn?',
    },
    '6×3=18、20-18=2 なので、3 あまり2です。' => {
      AppLanguage.portuguese: 'Como 6 × 3 = 18 e 20 − 18 = 2, a resposta é 3 resto 2.',
      AppLanguage.tagalog: 'Dahil 6 × 3 = 18 at 20 − 18 = 2, ang sagot ay 3 sobra 2.',
      AppLanguage.vietnamese: 'Vì 6 × 3 = 18 và 20 − 18 = 2 nên đáp án là 3 dư 2.',
    },
    '6こ入りの袋を作ります。いっぱいの袋はいくつできますか。' => {
      AppLanguage.portuguese: 'Fazemos sacos de 6. Quantos sacos cheios dá para fazer?',
      AppLanguage.tagalog: 'Gumagawa tayo ng bag na tig-6. Ilang punong bag ang magagawa?',
      AppLanguage.vietnamese: 'Làm túi đựng 6 cái. Được bao nhiêu túi đầy?',
    },
    '6人乗りの車に29人が乗ります。みんなが乗るには何台いりますか。' => {
      AppLanguage.portuguese: 'Um carro leva 6 pessoas e há 29 pessoas. Quantos carros precisamos para todos?',
      AppLanguage.tagalog: '6 tao ang kasya sa isang kotse at 29 ang tao. Ilang kotse para masakyan lahat?',
      AppLanguage.vietnamese: 'Xe 6 chỗ, có 29 người. Cần bao nhiêu xe để mọi người lên?',
    },
    '「あまり」は、どの数のことですか。' => {
      AppLanguage.portuguese: 'O «resto» é qual número?',
      AppLanguage.tagalog: 'Aling numero ang «sobra»?',
      AppLanguage.vietnamese: '「Số dư」là số nào?',
    },
    '「ぴったり分けられる」は、どういうことですか。' => {
      AppLanguage.portuguese: 'O que significa «dividir exatamente»?',
      AppLanguage.tagalog: 'Ano ang ibig sabihin ng «pantay na mahahati»?',
      AppLanguage.vietnamese: '「Chia vừa khít」nghĩa là gì?',
    },
    '「商」は、わり算の答えの大きい数です。「あまり」は残った数です。' => {
      AppLanguage.portuguese: 'O quociente é o número grande da resposta. O resto é o que sobrou.',
      AppLanguage.tagalog: 'Ang quotient ay ang malaking numero sa sagot. Ang sobra ay ang natirang numero.',
      AppLanguage.vietnamese: 'Thương là số lớn trong đáp án phép chia. Số dư là số còn lại.',
    },
    'あまった人も乗る必要があるので、車を1台増やします。' => {
      AppLanguage.portuguese: 'As pessoas que sobraram também precisam ir, então aumentamos 1 carro.',
      AppLanguage.tagalog: 'Kailangan ding sumakay ang natirang tao, kaya dagdag tayo ng 1 kotse.',
      AppLanguage.vietnamese: 'Người còn lại cũng cần lên xe nên thêm 1 xe.',
    },
    'あまり7は、わる数4より大きいです。もう1つまとまりを作れます。' => {
      AppLanguage.portuguese: 'O resto 7 é maior que o divisor 4. Dá para formar mais um grupo.',
      AppLanguage.tagalog: 'Mas malaki ang sobrang 7 kaysa panghating 4. Makakagawa pa ng isa pang grupo.',
      AppLanguage.vietnamese: 'Số dư 7 lớn hơn số chia 4. Còn làm thêm được một nhóm.',
    },
    'あまり7は、わる数4より小さいですか。' => {
      AppLanguage.portuguese: 'O resto 7 é menor que o divisor 4?',
      AppLanguage.tagalog: 'Mas maliit ba ang sobrang 7 kaysa panghating 4?',
      AppLanguage.vietnamese: 'Số dư 7 có nhỏ hơn số chia 4 không?',
    },
    'あまりがわる数以上なら、まだもう1つまとまりを作れます。' => {
      AppLanguage.portuguese: 'Se o resto for maior ou igual ao divisor, ainda dá para formar mais um grupo.',
      AppLanguage.tagalog: 'Kung ang sobra ay mas malaki o pareho sa panghati, makakagawa pa ng isa pang grupo.',
      AppLanguage.vietnamese: 'Nếu số dư lớn hơn hoặc bằng số chia thì còn làm thêm được một nhóm.',
    },
    'あまりが大きすぎたら、もう1つまとまりを作れるか考えます。' => {
      AppLanguage.portuguese: 'Se o resto estiver grande demais, pensamos se dá para formar mais um grupo.',
      AppLanguage.tagalog: 'Kung sobrang laki ng natira, isipin kung makakagawa pa ng isa pang grupo.',
      AppLanguage.vietnamese: 'Nếu số dư quá lớn, hãy nghĩ xem còn làm thêm được một nhóm không.',
    },
    'あまりのある式を読むためのことばです。' => {
      AppLanguage.portuguese: 'São palavras para ler contas com resto.',
      AppLanguage.tagalog: 'Mga salita para basahin ang pahayag na may sobra.',
      AppLanguage.vietnamese: 'Từ để đọc phép tính có số dư.',
    },
    'あまりは5cmに足りないので、5cmのリボンとして数えません。' => {
      AppLanguage.portuguese: 'O resto não chega a 5 cm, então não conta como uma fita de 5 cm.',
      AppLanguage.tagalog: 'Kulang sa 5 cm ang natira, kaya hindi ito binibilang na lasong 5 cm.',
      AppLanguage.vietnamese: 'Phần còn lại không đủ 5 cm nên không tính là một đoạn ruy-băng 5 cm.',
    },
    'あまりは、分けたあとに残る数です。' => {
      AppLanguage.portuguese: 'O resto é o número que fica depois de dividir.',
      AppLanguage.tagalog: 'Ang sobra ay ang numerong natitira pagkatapos maghati.',
      AppLanguage.vietnamese: 'Số dư là số còn lại sau khi chia.',
    },
    'あまりは必要な長さに足りないので、1本として数えません。' => {
      AppLanguage.portuguese: 'O resto não chega ao comprimento necessário, então não conta como 1 pedaço.',
      AppLanguage.tagalog: 'Kulang ang natira sa kailangang haba, kaya hindi ito binibilang na 1 piraso.',
      AppLanguage.vietnamese: 'Phần còn lại không đủ độ dài cần thiết nên không tính là 1 đoạn.',
    },
    'あまりをどうするかは、問題の場面で決めます。' => {
      AppLanguage.portuguese: 'O que fazer com o resto depende da situação do problema.',
      AppLanguage.tagalog: 'Ang gagawin sa sobra ay nakadepende sa sitwasyon ng problema.',
      AppLanguage.vietnamese: 'Xử lý số dư thế nào thì dựa vào tình huống bài toán.',
    },
    'あまりを答えにどう使うか考えるためのことばです。' => {
      AppLanguage.portuguese: 'São palavras para pensar como usar o resto na resposta.',
      AppLanguage.tagalog: 'Mga salita para isipin kung paano gagamitin ang sobra sa sagot.',
      AppLanguage.vietnamese: 'Từ để nghĩ cách dùng số dư trong đáp án.',
    },
    'あまるものはえんぴつなので、単位は本です。' => {
      AppLanguage.portuguese: 'O que sobra são lápis, então a unidade é hon (lápis).',
      AppLanguage.tagalog: 'Lapis ang natitira, kaya hon (lapis) ang yunit.',
      AppLanguage.vietnamese: 'Cái còn lại là bút chì nên đơn vị là hon (cây).',
    },
    'あめ14こを4こずつにします。残りはありますか。' => {
      AppLanguage.portuguese: 'Há 14 balas em grupos de 4. Sobram algumas?',
      AppLanguage.tagalog: '14 kendi na tig-4. May natitira ba?',
      AppLanguage.vietnamese: '14 viên kẹo, nhóm 4 viên. Có còn dư không?',
    },
    'あめ19こを6こずつにします。あまりはいくつですか。' => {
      AppLanguage.portuguese: 'Há 19 balas em grupos de 6. Qual é o resto?',
      AppLanguage.tagalog: '19 kendi na tig-6. Ilan ang sobra?',
      AppLanguage.vietnamese: '19 viên kẹo, nhóm 6 viên. Số dư là bao nhiêu?',
    },
    'あめ23こを4人で分けます。どの式ですか。' => {
      AppLanguage.portuguese: 'Há 23 balas para 4 pessoas. Qual é a conta?',
      AppLanguage.tagalog: '23 kendi para sa 4 tao. Alin ang pahayag?',
      AppLanguage.vietnamese: '23 viên kẹo chia cho 4 người. Phép tính nào?',
    },
    'あめ23こを4人で分けるので、23÷4です。' => {
      AppLanguage.portuguese: 'Como dividimos 23 balas entre 4 pessoas, a conta é 23 ÷ 4.',
      AppLanguage.tagalog: 'Dahil hinati ang 23 kendi sa 4 tao, 23 ÷ 4 ang pahayag.',
      AppLanguage.vietnamese: 'Vì chia 23 viên kẹo cho 4 người nên phép tính là 23 ÷ 4.',
    },
    'あめ23こを4人で同じ数ずつ分けます。1人は何こ、残りは何こですか。' => {
      AppLanguage.portuguese: '23 balas igualmente entre 4 pessoas. Quantas cada um recebe e quanto sobra?',
      AppLanguage.tagalog: '23 kendi na pantay sa 4 tao. Ilan ang sa bawat isa, at ilan ang natira?',
      AppLanguage.vietnamese: '23 viên kẹo chia đều cho 4 người. Mỗi người được bao nhiêu, còn dư bao nhiêu?',
    },
    'あめ5こを2こずつにします。残るあめは何こですか。' => {
      AppLanguage.portuguese: 'Há 5 balas em grupos de 2. Quantas balas sobram?',
      AppLanguage.tagalog: '5 kendi na tig-2. Ilang kendi ang matitira?',
      AppLanguage.vietnamese: '5 viên kẹo, nhóm 2 viên. Còn lại bao nhiêu viên?',
    },
    'あめを4こずつ分けると、3組できて、2こ残ります。' => {
      AppLanguage.portuguese: 'Dividindo as balas de 4 em 4, formamos 3 grupos e sobram 2.',
      AppLanguage.tagalog: 'Kung tig-4 ang kendi, 3 grupo ang magagawa at 2 ang matitira.',
      AppLanguage.vietnamese: 'Chia kẹo từng 4 viên thì được 3 nhóm và còn 2.',
    },
    'あめを6こずつ分けると、3組できて、1こ残ります。' => {
      AppLanguage.portuguese: 'Dividindo as balas de 6 em 6, formamos 3 grupos e sobra 1.',
      AppLanguage.tagalog: 'Kung tig-6 ang kendi, 3 grupo ang magagawa at 1 ang matitira.',
      AppLanguage.vietnamese: 'Chia kẹo từng 6 viên thì được 3 nhóm và còn 1.',
    },
    'できるまとまりの数を聞いているので、単位は束です。' => {
      AppLanguage.portuguese: 'Estamos perguntando o número de grupos, então a unidade é feixe.',
      AppLanguage.tagalog: 'Ang tanong ay ilang grupo, kaya bunso (taba) ang yunit.',
      AppLanguage.vietnamese: 'Đang hỏi số bó nên đơn vị là bó.',
    },
    'なぜあまりのリボンを数えませんか。' => {
      AppLanguage.portuguese: 'Por que não contamos a fita que sobrou?',
      AppLanguage.tagalog: 'Bakit hindi binibilang ang natirang laso?',
      AppLanguage.vietnamese: 'Vì sao không tính đoạn ruy-băng còn lại?',
    },
    'なぜ短い残りを1本にしませんか。' => {
      AppLanguage.portuguese: 'Por que o pedaço curto que sobrou não conta como 1?',
      AppLanguage.tagalog: 'Bakit hindi binibilang na 1 piraso ang maikling natira?',
      AppLanguage.vietnamese: 'Vì sao đoạn ngắn còn lại không tính là 1?',
    },
    'なぜ車を1台増やしますか。' => {
      AppLanguage.portuguese: 'Por que aumentamos 1 carro?',
      AppLanguage.tagalog: 'Bakit dagdag tayo ng 1 kotse?',
      AppLanguage.vietnamese: 'Vì sao thêm 1 xe?',
    },
    'なぜ車をもう1台用意しますか。' => {
      AppLanguage.portuguese: 'Por que preparamos mais 1 carro?',
      AppLanguage.tagalog: 'Bakit maghahanda pa tayo ng 1 kotse?',
      AppLanguage.vietnamese: 'Vì sao chuẩn bị thêm 1 xe?',
    },
    'ぴったり分けられるとき、あまりは出ません。' => {
      AppLanguage.portuguese: 'Quando dá para dividir exatamente, não há resto.',
      AppLanguage.tagalog: 'Kapag pantay na mahahati, walang sobra.',
      AppLanguage.vietnamese: 'Khi chia vừa khít thì không có số dư.',
    },
    'わる数を何回作れるか考えます。残った数を「あまり」として書きます。' => {
      AppLanguage.portuguese: 'Pensamos quantas vezes dá para formar o divisor. O que sobra se escreve como resto.',
      AppLanguage.tagalog: 'Isipin kung ilang beses magagawa ang panghati. Ang natira ay isinusulat na sobra.',
      AppLanguage.vietnamese: 'Nghĩ xem làm được bao nhiêu lần số chia. Số còn lại viết là số dư.',
    },
    'カード19まいを、1人に6まいずつ配ります。何人、残りは何まいですか。' => {
      AppLanguage.portuguese: '19 cartas, 6 para cada pessoa. Para quantas pessoas dá e quantas sobram?',
      AppLanguage.tagalog: '19 kard, tig-6 sa bawat tao. Para sa ilang tao, at ilan ang natira?',
      AppLanguage.vietnamese: '19 tấm thẻ, mỗi người 6 tấm. Đủ cho bao nhiêu người, còn bao nhiêu tấm?',
    },
    'クッキー10こを4こずつにします。残りは何こですか。' => {
      AppLanguage.portuguese: 'Há 10 biscoitos em grupos de 4. Quantos sobram?',
      AppLanguage.tagalog: '10 biskwit na tig-4. Ilan ang matitira?',
      AppLanguage.vietnamese: '10 cái bánh, nhóm 4 cái. Còn lại bao nhiêu?',
    },
    'クッキー12こを4こずつにします。残りはありますか。' => {
      AppLanguage.portuguese: 'Há 12 biscoitos em grupos de 4. Sobram alguns?',
      AppLanguage.tagalog: '12 biskwit na tig-4. May natitira ba?',
      AppLanguage.vietnamese: '12 cái bánh, nhóm 4 cái. Có còn dư không?',
    },
    'クッキー17こを5こずつにします。ふくろはいくつ、残りは何こですか。' => {
      AppLanguage.portuguese: '17 biscoitos em grupos de 5. Quantos sacos e quanto sobra?',
      AppLanguage.tagalog: '17 biskwit na tig-5. Ilang bag, at ilan ang natira?',
      AppLanguage.vietnamese: '17 cái bánh, nhóm 5 cái. Được bao nhiêu túi, còn bao nhiêu?',
    },
    'クッキー17こを5こずつにするので、17÷5です。' => {
      AppLanguage.portuguese: 'Como fazemos grupos de 5 com 17 biscoitos, a conta é 17 ÷ 5.',
      AppLanguage.tagalog: 'Dahil tig-5 ang 17 biskwit, 17 ÷ 5 ang pahayag.',
      AppLanguage.vietnamese: 'Vì gom 17 cái bánh thành nhóm 5 nên phép tính là 17 ÷ 5.',
    },
    'クッキー17こを、5こずつにします。どの式ですか。' => {
      AppLanguage.portuguese: 'Há 17 biscoitos em grupos de 5. Qual é a conta?',
      AppLanguage.tagalog: '17 biskwit na tig-5. Alin ang pahayag?',
      AppLanguage.vietnamese: '17 cái bánh, nhóm 5 cái. Phép tính nào?',
    },
    'クッキー34こを5こずつにします。どの式ですか。' => {
      AppLanguage.portuguese: 'Há 34 biscoitos em grupos de 5. Qual é a conta?',
      AppLanguage.tagalog: '34 biskwit na tig-5. Alin ang pahayag?',
      AppLanguage.vietnamese: '34 cái bánh, nhóm 5 cái. Phép tính nào?',
    },
    'クッキーを4こずつ分けると、3組できて、あまりはありません。' => {
      AppLanguage.portuguese: 'Dividindo os biscoitos de 4 em 4, formamos 3 grupos e não há resto.',
      AppLanguage.tagalog: 'Kung tig-4 ang biskwit, 3 grupo ang magagawa at walang sobra.',
      AppLanguage.vietnamese: 'Chia bánh từng 4 cái thì được 3 nhóm và không dư.',
    },
    'シール13こを5こずつにします。残りは何こですか。' => {
      AppLanguage.portuguese: 'Há 13 adesivos em grupos de 5. Quantos sobram?',
      AppLanguage.tagalog: '13 sticker na tig-5. Ilan ang matitira?',
      AppLanguage.vietnamese: '13 tem, nhóm 5 cái. Còn lại bao nhiêu?',
    },
    'シール15こを5こずつにすると、残りはありません。正しいですか。' => {
      AppLanguage.portuguese: '15 adesivos em grupos de 5 não deixam resto. Está certo?',
      AppLanguage.tagalog: '15 sticker na tig-5, walang natitira. Tama ba?',
      AppLanguage.vietnamese: '15 tem nhóm 5 thì không còn dư. Đúng không?',
    },
    'シールを5こずつ分けると、3組できて、あまりはありません。' => {
      AppLanguage.portuguese: 'Dividindo os adesivos de 5 em 5, formamos 3 grupos e não há resto.',
      AppLanguage.tagalog: 'Kung tig-5 ang sticker, 3 grupo ang magagawa at walang sobra.',
      AppLanguage.vietnamese: 'Chia tem từng 5 cái thì được 3 nhóm và không dư.',
    },
    'ビー玉31こを7人で分けます。1人は何こ、残りは何こですか。' => {
      AppLanguage.portuguese: '31 bolinhas entre 7 pessoas. Quantas cada um recebe e quanto sobra?',
      AppLanguage.tagalog: '31 bolitas sa 7 tao. Ilan ang sa bawat isa, at ilan ang natira?',
      AppLanguage.vietnamese: '31 viên bi chia cho 7 người. Mỗi người được bao nhiêu, còn bao nhiêu?',
    },
    '何を聞かれているかを見ると、答えの単位が分かります。' => {
      AppLanguage.portuguese: 'Olhando o que a pergunta pede, entendemos a unidade da resposta.',
      AppLanguage.tagalog: 'Kung titingnan kung ano ang tinatanong, malalaman ang yunit ng sagot.',
      AppLanguage.vietnamese: 'Nhìn xem câu hỏi đang hỏi gì thì biết đơn vị của đáp án.',
    },
    '何束できるかを聞いています。答えの単位はどれですか。' => {
      AppLanguage.portuguese: 'Estamos perguntando quantos feixes dá para fazer. Qual é a unidade?',
      AppLanguage.tagalog: 'Tinatanong kung ilang taba. Ano ang yunit ng sagot?',
      AppLanguage.vietnamese: 'Đang hỏi được bao nhiêu bó. Đơn vị đáp án là gì?',
    },
    '全部の34このクッキーを、5こずつ分けるので、式は34÷5です。' => {
      AppLanguage.portuguese: 'Como dividimos todos os 34 biscoitos de 5 em 5, a conta é 34 ÷ 5.',
      AppLanguage.tagalog: 'Dahil hinati ang lahat ng 34 biskwit nang tig-5, 34 ÷ 5 ang pahayag.',
      AppLanguage.vietnamese: 'Vì chia hết 34 cái bánh thành nhóm 5 nên phép tính là 34 ÷ 5.',
    },
    '分けたあとに残った数が、あまりです。' => {
      AppLanguage.portuguese: 'O número que fica depois de dividir é o resto.',
      AppLanguage.tagalog: 'Ang numerong natira pagkatapos maghati ay ang sobra.',
      AppLanguage.vietnamese: 'Số còn lại sau khi chia chính là số dư.',
    },
    '分けたあとに残る数が、あまりです。' => {
      AppLanguage.portuguese: 'O número que resta depois de dividir é o resto.',
      AppLanguage.tagalog: 'Ang numerong natitira pagkatapos maghati ay ang sobra.',
      AppLanguage.vietnamese: 'Số còn lại sau khi chia là số dư.',
    },
    '文章の意味を見て、あまりをどうするか決めます。' => {
      AppLanguage.portuguese: 'Olhamos o sentido do texto para decidir o que fazer com o resto.',
      AppLanguage.tagalog: 'Tingnan ang kahulugan ng pangungusap para magpasya sa sobra.',
      AppLanguage.vietnamese: 'Nhìn nghĩa của câu để quyết định xử lý số dư thế nào.',
    },
    '文章を読んで、ぜんぶの数、分ける数、何を聞いているかを見ます。' => {
      AppLanguage.portuguese: 'Lemos o texto e vemos o total, o número que divide e o que está sendo perguntado.',
      AppLanguage.tagalog: 'Basahin ang pangungusap at tingnan ang kabuuan, panghati, at kung ano ang tanong.',
      AppLanguage.vietnamese: 'Đọc câu rồi xem tổng số, số chia, và câu hỏi đang hỏi gì.',
    },
    '残りがまだ分けられる数のとき、どう考えますか。' => {
      AppLanguage.portuguese: 'Quando o que sobrou ainda dá para dividir, como pensamos?',
      AppLanguage.tagalog: 'Kung ang natira ay mahahati pa, paano tayo mag-iisip?',
      AppLanguage.vietnamese: 'Khi phần còn lại vẫn chia được nữa thì nghĩ thế nào?',
    },
    '残るえんぴつの数を聞いています。単位はどれですか。' => {
      AppLanguage.portuguese: 'Estamos perguntando o número de lápis que sobram. Qual é a unidade?',
      AppLanguage.tagalog: 'Tinatanong kung ilang lapis ang matitira. Ano ang yunit?',
      AppLanguage.vietnamese: 'Đang hỏi số bút chì còn lại. Đơn vị là gì?',
    },
    '答えの単位は、聞かれている言葉を見て選びます。' => {
      AppLanguage.portuguese: 'A unidade da resposta se escolhe olhando as palavras da pergunta.',
      AppLanguage.tagalog: 'Ang yunit ng sagot ay pinipili ayon sa mga salitang tinatanong.',
      AppLanguage.vietnamese: 'Đơn vị đáp án chọn theo từ ngữ câu hỏi.',
    },
    '車が何台必要かを聞いています。単位はどれですか。' => {
      AppLanguage.portuguese: 'Estamos perguntando quantos carros são necessários. Qual é a unidade?',
      AppLanguage.tagalog: 'Tinatanong kung ilang kotse ang kailangan. Ano ang yunit?',
      AppLanguage.vietnamese: 'Đang hỏi cần bao nhiêu xe. Đơn vị là gì?',
    },
    '車の数を聞いているので、単位は台です。' => {
      AppLanguage.portuguese: 'Estamos perguntando o número de carros, então a unidade é dai (carros).',
      AppLanguage.tagalog: 'Ang tanong ay bilang ng kotse, kaya dai (kotse) ang yunit.',
      AppLanguage.vietnamese: 'Đang hỏi số xe nên đơn vị là đài (chiếc).',
    },
    _ => const {},
  };
}
