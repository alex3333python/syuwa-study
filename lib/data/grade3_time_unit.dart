import '../models/app_language.dart';
import '../models/lesson.dart';
import '../models/question.dart';

final List<Lesson> grade3TimeLessons = [
  Lesson(
    id: 18,
    levelId: 3,
    type: LessonType.practice,
    title: '時こくや時間の求め方',
    description: '時計を動かして、時こくと時間のちがいを考えます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'time-main-learn',
        title: '学習しよう',
        school: '時計を動かして、時こくと時間のちがいを考えます。',
        easy: '時計を進めたり戻したりして、時間を見ます。',
        native: {
          AppLanguage.portuguese:
              'Vamos mover o relógio para entender horário e duração.',
        },
      ),
      _learn(
        id: 'time-main-words',
        title: 'ことばを知ろう',
        school: 'このレッスンで使うことばを確認します。',
        easy: '時計の問題で使う言葉です。',
      ),
      LessonStep(
        id: 'time-main-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに考えよう',
        questions: [
          _q(
            id: 18101,
            type: 'elapsed_time',
            school: '7時45分に家を出て、8時10分に学校につきました。何分かかりましたか。',
            easy: '7時45分から8時10分までの時間を考えます。',
            native: {
              AppLanguage.portuguese:
                  'Saiu de casa às 7:45 e chegou à escola às 8:10. Quantos minutos levou?',
            },
            questionTextRuby:
                '7{時|じ}45{分|ふん}に{家|いえ}を{出|で}て、8{時|じ}10{分|ぷん}に{学校|がっこう}につきました。{何分|なんぷん}かかりましたか。',
            choices: ['15分', '25分', '35分'],
            correct: 1,
            explanation: '7時45分から8時までは15分、8時から8時10分までは10分です。15分+10分=25分です。',
            explanationRuby:
                '7{時|じ}45{分|ふん}から8{時|じ}までは15{分|ふん}、8{時|じ}から8{時|じ}10{分|ぷん}までは10{分|ぷん}です。15{分|ふん}+10{分|ぷん}=25{分|ふん}です。',
            tags: ['time', 'elapsed_time', 'across_hour'],
            diagramData: const {
              'points': '7:45|8:00|8:10',
              'spans': '15分|10分',
              'caption': '15分 + 10分 = 25分',
            },
          ),
          _q(
            id: 18102,
            type: 'minutes_after',
            school: '8時10分から20分後は何時何分ですか。',
            easy: '8時10分から20分進めます。',
            native: {
              AppLanguage.portuguese:
                  'Que horas são 20 minutos depois das 8:10?',
            },
            questionTextRuby:
                '8{時|じ}10{分|ぷん}から20{分|ぷん}{後|ご}は{何時|なんじ}{何分|なんぷん}ですか。',
            choices: ['8時20分', '8時30分', '8時40分'],
            correct: 1,
            explanation: '8時10分から時計を20分進めると、8時30分になります。',
            explanationRuby:
                '8{時|じ}10{分|ぷん}から{時計|とけい}を20{分|ぷん}{進|すす}めると、8{時|じ}30{分|ぷん}になります。',
            tags: ['time', 'minutes_after'],
            diagramData: const {
              'points': '8:10|8:30',
              'spans': '20分',
              'caption': '20分後は8時30分',
            },
          ),
          _q(
            id: 18103,
            type: 'minutes_before',
            school: '8時10分につきました。25分前は何時何分ですか。',
            easy: '8時10分から25分戻します。',
            native: {
              AppLanguage.portuguese:
                  'Chegou às 8:10. Que horas eram 25 minutos antes?',
            },
            questionTextRuby:
                '8{時|じ}10{分|ぷん}につきました。25{分|ふん}{前|まえ}は{何時|なんじ}{何分|なんぷん}ですか。',
            choices: ['7時35分', '7時45分', '8時35分'],
            correct: 1,
            explanation: '8時10分から10分戻ると8時、さらに15分戻ると7時45分です。',
            explanationRuby:
                '8{時|じ}10{分|ぷん}から10{分|ぷん}{戻|もど}ると8{時|じ}、さらに15{分|ふん}{戻|もど}ると7{時|じ}45{分|ふん}です。',
            tags: ['time', 'minutes_before', 'start_time'],
            diagramData: const {
              'points': '7:45|8:00|8:10',
              'spans': '15分|10分',
              'caption': '25分前は7時45分',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'time-main-practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 18104,
            type: 'across_hour',
            school: '9時45分から30分後は何時何分ですか。',
            easy: '9時45分から30分進めます。',
            questionTextRuby:
                '9{時|じ}45{分|ふん}から30{分|ぷん}{後|ご}は{何時|なんじ}{何分|なんぷん}ですか。',
            choices: ['10時5分', '10時15分', '10時30分'],
            correct: 1,
            explanation: '9時45分から10時までは15分です。あと15分進めると10時15分です。',
            explanationRuby:
                '9{時|じ}45{分|ふん}から10{時|じ}までは15{分|ふん}です。あと15{分|ふん}{進|すす}めると10{時|じ}15{分|ふん}です。',
            tags: ['time', 'minutes_after', 'across_hour'],
            diagramData: const {
              'points': '9:45|10:00|10:15',
              'spans': '15分|15分',
              'caption': '30分後は10時15分',
            },
          ),
          _q(
            id: 18105,
            type: 'noon',
            school: '午前11時40分から50分後は何時何分ですか。',
            easy: '11時40分から50分進めます。12時をまたぎます。',
            questionTextRuby:
                '{午前|ごぜん}11{時|じ}40{分|ぷん}から50{分|ぷん}{後|ご}は{何時|なんじ}{何分|なんぷん}ですか。',
            choices: ['午後0時30分', '午前12時10分', '午後1時30分'],
            correct: 0,
            explanation: '午前11時40分から正午までは20分です。あと30分進めると午後0時30分です。',
            explanationRuby:
                '{午前|ごぜん}11{時|じ}40{分|ぷん}から{正午|しょうご}までは20{分|ぷん}です。あと30{分|ぷん}{進|すす}めると{午後|ごご}0{時|じ}30{分|ぷん}です。',
            tags: ['time', 'noon', 'am_pm'],
            diagramData: const {
              'points': '午前11:40|正午|午後0:30',
              'spans': '20分|30分',
              'caption': '50分後は午後0時30分',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'time-main-japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 18106,
            type: 'start_time',
            school: '10時に学校につきました。家から学校まで30分かかりました。何時に家を出ましたか。',
            easy: '10時から30分戻します。',
            choices: ['9時20分', '9時30分', '10時30分'],
            correct: 1,
            explanation: '10時から30分戻すと、9時30分です。',
            tags: ['time', 'start_time'],
            diagramData: const {
              'points': '9:30|10:00',
              'spans': '30分',
              'caption': '30分前は9時30分',
            },
          ),
        ],
      ),
    ],
  ),
  Lesson(
    id: 19,
    levelId: 3,
    type: LessonType.practice,
    title: '短い時間',
    description: '秒を体感して、分と秒の関係を考えます。',
    completed: false,
    locked: true,
    stars: 0,
    maxStars: 3,
    questions: const [],
    steps: [
      _learn(
        id: 'time-short-learn',
        title: '学習しよう',
        school: '秒を体で感じて、1分が60秒であることを考えます。',
        easy: '短い時間を体感します。',
        native: {
          AppLanguage.portuguese:
              'Vamos sentir os segundos e ver que 1 minuto tem 60 segundos.',
        },
      ),
      _learn(
        id: 'time-short-words',
        title: 'ことばを知ろう',
        school: '秒や分を表すことばを確認します。',
        easy: '短い時間の言葉です。',
      ),
      LessonStep(
        id: 'time-short-guided',
        type: LessonStepType.guidedPractice,
        title: 'いっしょに考えよう',
        questions: [
          _q(
            id: 19101,
            type: 'seconds_unit',
            school: '1分は何秒ですか。',
            easy: '秒針が1周すると何秒ですか。',
            native: {
              AppLanguage.portuguese: 'Quantos segundos há em 1 minuto?',
            },
            questionTextRuby: '1{分|ぷん}は{何秒|なんびょう}ですか。',
            choices: ['30秒', '60秒', '100秒'],
            correct: 1,
            explanation: '秒針が時計を1周すると60秒です。1分は60秒です。',
            explanationRuby:
                '{秒針|びょうしん}が{時計|とけい}を1{周|しゅう}すると60{秒|びょう}です。1{分|ぷん}は60{秒|びょう}です。',
            tags: ['time', 'seconds'],
            diagramData: const {
              'points': '0秒|30秒|60秒',
              'spans': '30秒|30秒',
              'caption': '60秒 = 1分',
            },
          ),
          _q(
            id: 19102,
            type: 'minutes_seconds',
            school: '1分20秒は何秒ですか。',
            easy: '60秒と20秒を合わせます。',
            native: {
              AppLanguage.portuguese:
                  '1 minuto e 20 segundos são quantos segundos?',
            },
            questionTextRuby: '1{分|ぷん}20{秒|びょう}は{何秒|なんびょう}ですか。',
            choices: ['70秒', '80秒', '120秒'],
            correct: 1,
            explanation: '1分は60秒です。60秒に20秒を足すと80秒です。',
            explanationRuby:
                '1{分|ぷん}は60{秒|びょう}です。60{秒|びょう}に20{秒|びょう}を{足|た}すと80{秒|びょう}です。',
            tags: ['time', 'seconds', 'conversion'],
            diagramData: const {
              'points': '0秒|60秒|80秒',
              'spans': '1分|20秒',
              'caption': '60秒 + 20秒 = 80秒',
            },
          ),
        ],
      ),
      LessonStep(
        id: 'time-short-practice',
        type: LessonStepType.independentPractice,
        title: '自分で解こう',
        questions: [
          _q(
            id: 19103,
            type: 'compare_time',
            school: '1分と50秒では、どちらが長いですか。',
            easy: '1分は60秒です。',
            questionTextRuby: '1{分|ぷん}と50{秒|びょう}では、どちらが{長|なが}いですか。',
            choices: ['1分', '50秒', '同じ'],
            correct: 0,
            explanation: '1分は60秒です。60秒は50秒より長いので、1分のほうが長いです。',
            explanationRuby:
                '1{分|ぷん}は60{秒|びょう}です。60{秒|びょう}は50{秒|びょう}より{長|なが}いので、1{分|ぷん}のほうが{長|なが}いです。',
            tags: ['time', 'compare_time'],
          ),
          _q(
            id: 19104,
            type: 'seconds_life',
            school: '50m走に12秒かかりました。これはどの単位で表していますか。',
            easy: '短い時間を表す単位を選びます。',
            questionTextRuby:
                '50m{走|そう}に12{秒|びょう}かかりました。これはどの{単位|たんい}で{表|あらわ}していますか。',
            choices: ['時', '分', '秒'],
            correct: 2,
            explanation: '50m走のような短い時間は、秒で表すことがあります。',
            explanationRuby:
                '50m{走|そう}のような{短|みじか}い{時間|じかん}は、{秒|びょう}で{表|あらわ}すことがあります。',
            tags: ['time', 'seconds_life'],
          ),
        ],
      ),
      LessonStep(
        id: 'time-short-japanese',
        type: LessonStepType.independentPractice,
        title: '日本語だけで挑戦',
        questions: [
          _q(
            id: 19105,
            type: 'minutes_seconds',
            school: '1分30秒は何秒ですか。',
            easy: '60秒と30秒を合わせます。',
            choices: ['70秒', '90秒', '130秒'],
            correct: 1,
            explanation: '1分は60秒です。60秒+30秒=90秒です。',
            tags: ['time', 'seconds', 'conversion'],
            diagramData: const {
              'points': '0秒|60秒|90秒',
              'spans': '1分|30秒',
              'caption': '60秒 + 30秒 = 90秒',
            },
          ),
        ],
      ),
    ],
  ),
  Lesson(
    id: 20,
    levelId: 3,
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
        id: 'time-check',
        type: LessonStepType.independentPractice,
        title: 'たしかめ問題',
        questions: [
          _q(
            id: 20101,
            type: 'elapsed_time',
            school: '7時50分に家を出て、8時15分に学校につきました。何分かかりましたか。',
            easy: '7時50分から8時15分までを考えます。',
            choices: ['15分', '25分', '35分'],
            correct: 1,
            explanation: '7時50分から8時までは10分、8時から8時15分までは15分です。合わせて25分です。',
            tags: ['time', 'elapsed_time'],
            diagramData: const {
              'points': '7:50|8:00|8:15',
              'spans': '10分|15分',
              'caption': '10分 + 15分 = 25分',
            },
          ),
          _q(
            id: 20102,
            type: 'minutes_after',
            school: '午後2時10分から45分勉強しました。終わった時こくは何時何分ですか。',
            easy: '午後2時10分から45分進めます。',
            choices: ['午後2時45分', '午後2時55分', '午後3時5分'],
            correct: 1,
            explanation: '午後2時10分から45分進めると、午後2時55分です。',
            tags: ['time', 'minutes_after', 'pm'],
            diagramData: const {
              'points': '午後2:10|午後2:55',
              'spans': '45分',
              'caption': '45分後は午後2時55分',
            },
          ),
          _q(
            id: 20103,
            type: 'noon',
            school: '午前11時40分に出発し、50分後に着きました。何時何分ですか。',
            easy: '午前11時40分から50分進めます。',
            choices: ['午前11時50分', '午後0時30分', '午後1時30分'],
            correct: 1,
            explanation: '午前11時40分から正午まで20分、さらに30分で午後0時30分です。',
            tags: ['time', 'noon', 'am_pm'],
            diagramData: const {
              'points': '午前11:40|正午|午後0:30',
              'spans': '20分|30分',
              'caption': '50分後は午後0時30分',
            },
          ),
          _q(
            id: 20104,
            type: 'minutes_seconds',
            school: '1分30秒は何秒ですか。',
            easy: '1分は60秒です。',
            choices: ['80秒', '90秒', '130秒'],
            correct: 1,
            explanation: '1分は60秒です。60秒+30秒=90秒です。',
            tags: ['time', 'seconds', 'conversion'],
            diagramData: const {
              'points': '0秒|60秒|90秒',
              'spans': '1分|30秒',
              'caption': '60秒 + 30秒 = 90秒',
            },
          ),
          _q(
            id: 20105,
            type: 'compare_time',
            school: '1分と50秒では、どちらが長いですか。',
            easy: '1分は60秒です。',
            choices: ['1分', '50秒', '同じ'],
            correct: 0,
            explanation: '1分は60秒です。60秒は50秒より長いです。',
            tags: ['time', 'compare_time'],
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
  Map<String, String> diagramData = const {},
}) {
  return Question(
    id: id,
    type: type,
    unitId: 'grade3_time',
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
    tags: ['grade3', 'math', 'time', ...tags],
    diagramType: diagramData.isEmpty ? '' : 'time_line',
    diagramData: diagramData,
    grade: 3,
    subject: 'math',
    unit: 'time',
  );
}
