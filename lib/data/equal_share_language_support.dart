import '../models/app_language.dart';
import '../models/question.dart';

class SupportLine {
  final String japanese;
  final String ruby;
  final Map<AppLanguage, String> native;

  const SupportLine({
    required this.japanese,
    this.ruby = '',
    this.native = const {},
  });

  String get rubyText => ruby.isNotEmpty ? ruby : japanese;

  String nativeFor(AppLanguage language) {
    return native[language] ?? '';
  }
}

class EquationSupport {
  final String value;
  final String label;
  final String meaning;
  final Map<AppLanguage, String> native;

  const EquationSupport({
    required this.value,
    required this.label,
    required this.meaning,
    this.native = const {},
  });

  String nativeFor(AppLanguage language) {
    return native[language] ?? '';
  }
}

enum LessonVocabularyVisual {
  equalGroups,
  splitToPlates,
  onePersonShare,
  countQuestion,
  divideByOne,
  zeroItems,
  divideByZero,
  remainder,
  divisor,
  dividend,
  roundUpRemainder,
  none,
}

class LessonVocabulary {
  final String word;
  final String reading;
  final String explanation;
  final Map<AppLanguage, String> translations;
  final LessonVocabularyVisual visual;

  const LessonVocabulary({
    required this.word,
    required this.reading,
    required this.explanation,
    required this.translations,
    required this.visual,
  });

  String translationFor(AppLanguage language) {
    return translations[language] ?? '';
  }
}

const equalShareProblemLines = [
  SupportLine(
    japanese: 'いちごが6こあります。',
    ruby: 'いちごが6こあります。',
    native: {
      AppLanguage.portuguese: 'Há 6 morangos.',
      AppLanguage.tagalog: 'May 6 na strawberry.',
      AppLanguage.vietnamese: 'Có 6 quả dâu.',
    },
  ),
  SupportLine(
    japanese: '3人で同じ数ずつ分けると、1人分は何こになりますか。',
    ruby: '3{人|にん}で{同じ数ずつ|おなじかずずつ}{分ける|わける}と、{1人|ひとり}{分|ぶん}は{何こ|なんこ}になりますか。',
    native: {
      AppLanguage.portuguese:
          'Se forem divididos igualmente entre 3 pessoas, quantos morangos cada pessoa recebe?',
      AppLanguage.tagalog:
          'Kung hahatiin nang pantay sa 3 tao, ilang strawberry ang para sa bawat isa?',
      AppLanguage.vietnamese:
          'Nếu chia đều cho 3 người, mỗi người được bao nhiêu quả?',
    },
  ),
];

const equalShareInstruction = SupportLine(
  japanese: 'いちごをおさらに分けてみよう！',
  ruby: 'いちごをお{皿|さら}に{分けて|わけて}みよう！',
  native: {
    AppLanguage.portuguese: 'Vamos dividir os morangos nos pratos!',
    AppLanguage.tagalog: 'Igalaw natin ang mga strawberry!',
    AppLanguage.vietnamese: 'Hãy chia dâu vào các đĩa!',
  },
);

const equalShareResultLines = [
  SupportLine(
    japanese: '同じ数ずつ分けられたね！',
    ruby: '{同じ数ずつ|おなじかずずつ}{分けられた|わけられた}ね！',
    native: {
      AppLanguage.portuguese: 'Você conseguiu dividir igualmente!',
      AppLanguage.tagalog: 'Nahati mo nang pantay!',
      AppLanguage.vietnamese: 'Em đã chia đều được rồi!',
    },
  ),
  SupportLine(
    japanese: 'どのお皿にも、いちごが2こずつあるね。',
    ruby: 'どのお{皿|さら}にも、いちごが2こずつあるね。',
    native: {
      AppLanguage.portuguese: 'Cada prato tem 2 morangos.',
      AppLanguage.tagalog: 'May tig-2 strawberry sa bawat plato.',
      AppLanguage.vietnamese: 'Mỗi đĩa đều có 2 quả dâu.',
    },
  ),
  SupportLine(
    japanese: 'いちご6こを、3人で同じ数ずつ分けると、1人分は2こになります。',
    ruby: 'いちご6こを、3{人|にん}で{同じ数ずつ|おなじかずずつ}{分ける|わける}と、{1人|ひとり}{分|ぶん}は2こになります。',
    native: {
      AppLanguage.portuguese:
          'Quando 6 morangos são divididos igualmente entre 3 pessoas, cada pessoa recebe 2.',
      AppLanguage.tagalog:
          'Kapag hinati ang 6 na strawberry nang pantay sa 3 tao, bawat isa ay may 2.',
      AppLanguage.vietnamese:
          'Khi chia đều 6 quả dâu cho 3 người, mỗi người được 2 quả.',
    },
  ),
  SupportLine(
    japanese: 'このことを式で 6 ÷ 3 = 2 と書いて、「6わる3は2」といいます。',
    ruby: 'このことを{式|しき}で 6 ÷ 3 = 2 と{書いて|かいて}、「6わる3は2」といいます。',
    native: {
      AppLanguage.portuguese:
          'Escrevemos isso como 6 ÷ 3 = 2 e lemos: “seis dividido por três é dois”.',
      AppLanguage.tagalog:
          'Isinusulat ito bilang 6 ÷ 3 = 2 at binabasa: “6 waru 3 wa 2”.',
      AppLanguage.vietnamese: 'Ta viết là 6 ÷ 3 = 2 và đọc: “6 waru 3 wa 2”.',
    },
  ),
];

const equalShareEquationReading = SupportLine(
  japanese: '6わる3は2',
  native: {
    AppLanguage.portuguese: 'seis dividido por três é dois',
    AppLanguage.tagalog: 'anim na hinati sa tatlo ay dalawa',
    AppLanguage.vietnamese: 'sáu chia ba bằng hai',
  },
);

const equalShareEquationSupports = [
  EquationSupport(
    value: '6',
    label: '全部の数',
    meaning: 'この問題に出てくる、いちご全部の数',
    native: {
      AppLanguage.portuguese: 'o número total de morangos',
      AppLanguage.tagalog: 'kabuuang bilang ng mga strawberry',
      AppLanguage.vietnamese: 'tổng số quả dâu',
    },
  ),
  EquationSupport(
    value: '3',
    label: '分ける人数',
    meaning: 'いちごを分ける人の数',
    native: {
      AppLanguage.portuguese: 'o número de pessoas',
      AppLanguage.tagalog: 'bilang ng mga taong paghahatian',
      AppLanguage.vietnamese: 'số người được chia',
    },
  ),
  EquationSupport(
    value: '2',
    label: '1人分の数',
    meaning: '1人がもらういちごの数',
    native: {
      AppLanguage.portuguese: 'quantidade para cada pessoa',
      AppLanguage.tagalog: 'bilang para sa bawat tao',
      AppLanguage.vietnamese: 'số quả mỗi người nhận',
    },
  ),
];

const equalShareLessonVocabulary = [
  LessonVocabulary(
    word: '同じ数ずつ',
    reading: 'おなじ かずずつ',
    explanation: 'みんなが同じ数になるように分けます。',
    translations: {
      AppLanguage.portuguese: 'a mesma quantidade para cada pessoa',
      AppLanguage.tagalog: 'parehong dami para sa bawat isa',
      AppLanguage.vietnamese: 'cùng một số lượng cho mỗi người',
    },
    visual: LessonVocabularyVisual.equalGroups,
  ),
  LessonVocabulary(
    word: '分ける',
    reading: 'わける',
    explanation: 'ものをいくつかのグループにします。',
    translations: {
      AppLanguage.portuguese: 'dividir / separar em grupos',
      AppLanguage.tagalog: 'hatiin sa mga pangkat',
      AppLanguage.vietnamese: 'chia thành các nhóm',
    },
    visual: LessonVocabularyVisual.splitToPlates,
  ),
  LessonVocabulary(
    word: '1人分',
    reading: 'ひとりぶん',
    explanation: '1人がもらう数です。',
    translations: {
      AppLanguage.portuguese: 'quantidade para uma pessoa',
      AppLanguage.tagalog: 'bahagi para sa isang tao',
      AppLanguage.vietnamese: 'phần cho một người',
    },
    visual: LessonVocabularyVisual.onePersonShare,
  ),
  LessonVocabulary(
    word: '何こ',
    reading: 'なんこ',
    explanation: 'ものの数を聞く言い方です。',
    translations: {
      AppLanguage.portuguese: 'quantos itens',
      AppLanguage.tagalog: 'ilang piraso',
      AppLanguage.vietnamese: 'bao nhiêu cái',
    },
    visual: LessonVocabularyVisual.countQuestion,
  ),
];

const equalShareVocabularyEntries = [
  VocabularyEntry(
    term: 'いちご',
    reading: 'いちご',
    simpleJapanese: '赤いくだものです。',
    translations: {
      AppLanguage.portuguese: 'morango',
      AppLanguage.tagalog: 'strawberry',
      AppLanguage.vietnamese: 'quả dâu',
    },
    exampleSentence: 'いちごが6こあります。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: 'お皿',
    reading: 'さら',
    simpleJapanese: '食べものをのせるものです。',
    translations: {
      AppLanguage.portuguese: 'prato',
      AppLanguage.tagalog: 'plato',
      AppLanguage.vietnamese: 'cái đĩa',
    },
    exampleSentence: 'お皿にいちごを置きます。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: '同じ数ずつ',
    reading: 'おなじかずずつ',
    simpleJapanese: 'みんなが同じ数になるように',
    translations: {
      AppLanguage.portuguese:
          'igualmente / a mesma quantidade para cada pessoa',
      AppLanguage.tagalog: 'pantay-pantay / parehong dami para sa bawat isa',
      AppLanguage.vietnamese: 'chia đều / cùng một số lượng cho mỗi người',
    },
    exampleSentence: '3人で同じ数ずつ分けます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '分ける',
    reading: 'わける',
    simpleJapanese: 'ものを、何人かに配る',
    translations: {
      AppLanguage.portuguese: 'dividir / distribuir',
      AppLanguage.tagalog: 'hatiin / ipamahagi',
      AppLanguage.vietnamese: 'chia / phân phát',
    },
    exampleSentence: 'いちごを3人で分けます。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '1人分',
    reading: 'ひとりぶん',
    simpleJapanese: '1人がもらう数',
    translations: {
      AppLanguage.portuguese: 'quantidade para uma pessoa',
      AppLanguage.tagalog: 'bahagi para sa isang tao',
      AppLanguage.vietnamese: 'phần cho một người',
    },
    exampleSentence: '1人分は2こです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '人',
    reading: 'にん',
    simpleJapanese: '人の数を数える言い方です。',
    translations: {
      AppLanguage.portuguese: 'pessoa(s)',
      AppLanguage.tagalog: 'tao',
      AppLanguage.vietnamese: 'người',
    },
    exampleSentence: '3人で分けます。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '何こ',
    reading: 'なんこ',
    simpleJapanese: '数を聞く言葉',
    translations: {
      AppLanguage.portuguese: 'quantos itens',
      AppLanguage.tagalog: 'ilang piraso',
      AppLanguage.vietnamese: 'bao nhiêu cái',
    },
    exampleSentence: '1人分は何こですか。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '式',
    reading: 'しき',
    simpleJapanese: '計算を、数字や記号で書いたものです。',
    translations: {
      AppLanguage.portuguese: 'conta / expressão matemática',
      AppLanguage.tagalog: 'pahayag sa matematika',
      AppLanguage.vietnamese: 'phép tính / biểu thức',
    },
    exampleSentence: '6 ÷ 3 = 2 は式です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '全部の数',
    reading: 'ぜんぶのかず',
    simpleJapanese: 'はじめにある、全部の数',
    translations: {
      AppLanguage.portuguese: 'número total',
      AppLanguage.tagalog: 'kabuuang bilang',
      AppLanguage.vietnamese: 'tổng số',
    },
    exampleSentence: '6は全部の数です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '人数',
    reading: 'にんずう',
    simpleJapanese: '人が何人いるか',
    translations: {
      AppLanguage.portuguese: 'número de pessoas',
      AppLanguage.tagalog: 'bilang ng tao',
      AppLanguage.vietnamese: 'số người',
    },
    exampleSentence: '3は分ける人数です。',
    category: 'math_language',
  ),
];

const measureDivisionProblemLines = [
  SupportLine(
    japanese: 'いちごが6こあります。',
    ruby: 'いちごが6こあります。',
    native: {
      AppLanguage.portuguese: 'Há 6 morangos.',
      AppLanguage.tagalog: 'May 6 na strawberry.',
      AppLanguage.vietnamese: 'Có 6 quả dâu.',
    },
  ),
  SupportLine(
    japanese: '1人に2こずつ分けると、何人に分けられますか。',
    ruby: '{1人|ひとり}に2こずつ{分ける|わける}と、{何人|なんにん}に{分けられます|わけられます}か。',
    native: {
      AppLanguage.portuguese:
          'Se dermos 2 morangos para cada pessoa, para quantas pessoas dá para dividir?',
      AppLanguage.tagalog:
          'Kung tig-2 strawberry ang bawat tao, ilang tao ang mabibigyan?',
      AppLanguage.vietnamese:
          'Nếu mỗi người nhận 2 quả dâu, chia được cho bao nhiêu người?',
    },
  ),
];

const measureDivisionInstruction = SupportLine(
  japanese: 'いちごを、1人に2こずつ分けてみよう！',
  ruby: 'いちごを、{1人|ひとり}に2こずつ{分けて|わけて}みよう！',
  native: {
    AppLanguage.portuguese: 'Vamos dar 2 morangos para cada pessoa!',
    AppLanguage.tagalog: 'Magbigay tayo ng tig-2 strawberry sa bawat tao!',
    AppLanguage.vietnamese: 'Hãy chia mỗi người 2 quả dâu!',
  },
);

const measureDivisionResultLines = [
  SupportLine(
    japanese: '3人に分けられたね！',
    ruby: '3{人|にん}に{分けられた|わけられた}ね！',
    native: {
      AppLanguage.portuguese: 'Deu para dividir para 3 pessoas!',
      AppLanguage.tagalog: 'Nahati para sa 3 tao!',
      AppLanguage.vietnamese: 'Chia được cho 3 người rồi!',
    },
  ),
  SupportLine(
    japanese: '1人目、2人目、3人目に、いちごが2こずつあるね。',
    ruby: '{1人|ひとり}{目|め}、2{人|にん}{目|め}、3{人|にん}{目|め}に、いちごが2こずつあるね。',
    native: {
      AppLanguage.portuguese:
          'A pessoa 1, a pessoa 2 e a pessoa 3 têm 2 morangos cada.',
      AppLanguage.tagalog: 'May tig-2 strawberry ang tao 1, tao 2, at tao 3.',
      AppLanguage.vietnamese: 'Người thứ 1, thứ 2 và thứ 3 đều có 2 quả dâu.',
    },
  ),
  SupportLine(
    japanese: 'いちご6こを、1人に2こずつ分けると、3人に分けられます。',
    ruby: 'いちご6こを、{1人|ひとり}に2こずつ{分ける|わける}と、3{人|にん}に{分けられます|わけられます}。',
    native: {
      AppLanguage.portuguese:
          'Quando 6 morangos são divididos dando 2 para cada pessoa, dá para 3 pessoas.',
      AppLanguage.tagalog:
          'Kapag ang 6 strawberry ay hinati nang tig-2 bawat tao, sapat ito para sa 3 tao.',
      AppLanguage.vietnamese:
          'Khi chia 6 quả dâu, mỗi người 2 quả, thì chia được cho 3 người.',
    },
  ),
  SupportLine(
    japanese: 'このことを式で 6 ÷ 2 = 3 と書いて、「6わる2は3」といいます。',
    ruby: 'このことを{式|しき}で 6 ÷ 2 = 3 と{書いて|かいて}、「6わる2は3」といいます。',
    native: {
      AppLanguage.portuguese:
          'Escrevemos isso como 6 ÷ 2 = 3 e lemos: “seis dividido por dois é três”.',
      AppLanguage.tagalog:
          'Isinusulat ito bilang 6 ÷ 2 = 3 at binabasa: “6 waru 2 wa 3”.',
      AppLanguage.vietnamese: 'Ta viết là 6 ÷ 2 = 3 và đọc: “6 waru 2 wa 3”.',
    },
  ),
  SupportLine(
    japanese: 'また、この式では、6を「わられる数」、2を「わる数」といいます。',
    ruby: 'また、この{式|しき}では、6を「わられる{数|かず}」、2を「わる{数|かず}」といいます。',
    native: {
      AppLanguage.portuguese:
          'Nesta conta, 6 é o número que será dividido, e 2 é o número pelo qual dividimos.',
      AppLanguage.tagalog:
          'Sa pangungusap na ito, ang 6 ang bilang na hinahati, at ang 2 ang bilang na pinaghahatuan.',
      AppLanguage.vietnamese:
          'Trong phép tính này, 6 là số bị chia, còn 2 là số chia.',
    },
  ),
];

const measureDivisionEquationReading = SupportLine(
  japanese: '6わる2は3',
  native: {
    AppLanguage.portuguese: 'seis dividido por dois é três',
    AppLanguage.tagalog: 'anim na hinati sa dalawa ay tatlo',
    AppLanguage.vietnamese: 'sáu chia hai bằng ba',
  },
);

const measureDivisionEquationSupports = [
  EquationSupport(
    value: '6',
    label: '全部の数',
    meaning: 'この式では、わられる数ともいいます',
    native: {
      AppLanguage.portuguese: 'número total / número que será dividido',
      AppLanguage.tagalog: 'kabuuang bilang / bilang na hinahati',
      AppLanguage.vietnamese: 'tổng số / số bị chia',
    },
  ),
  EquationSupport(
    value: '2',
    label: '1人分の数',
    meaning: 'この式では、わる数ともいいます',
    native: {
      AppLanguage.portuguese: 'quantidade para cada pessoa / número divisor',
      AppLanguage.tagalog: 'bilang para sa bawat tao / bilang na pinaghahatuan',
      AppLanguage.vietnamese: 'số cho mỗi người / số chia',
    },
  ),
  EquationSupport(
    value: '3',
    label: '分けられる人数',
    meaning: 'いちごを分けられる人の数',
    native: {
      AppLanguage.portuguese: 'o número de pessoas que podem receber',
      AppLanguage.tagalog: 'bilang ng taong mabibigyan',
      AppLanguage.vietnamese: 'số người có thể nhận',
    },
  ),
];

const measureDivisionLessonVocabulary = [
  LessonVocabulary(
    word: '何こずつ',
    reading: 'なんこずつ',
    explanation: '1人に何こずつ分けるかを表します。',
    translations: {
      AppLanguage.portuguese: 'quantos para cada pessoa',
      AppLanguage.tagalog: 'tig-ilan para sa bawat tao',
      AppLanguage.vietnamese: 'mỗi người bao nhiêu cái',
    },
    visual: LessonVocabularyVisual.onePersonShare,
  ),
  LessonVocabulary(
    word: '何人',
    reading: 'なんにん',
    explanation: '人の数を聞く言い方です。',
    translations: {
      AppLanguage.portuguese: 'quantas pessoas',
      AppLanguage.tagalog: 'ilang tao',
      AppLanguage.vietnamese: 'bao nhiêu người',
    },
    visual: LessonVocabularyVisual.countQuestion,
  ),
];

const zeroOneDivisionLessonVocabulary = [
  LessonVocabulary(
    word: '1でわる',
    reading: 'いちで わる',
    explanation: '1人で分けることです。全部その人がもらいます。',
    translations: {
      AppLanguage.portuguese: 'dividir por 1',
      AppLanguage.tagalog: 'hatiin sa 1',
      AppLanguage.vietnamese: 'chia cho 1',
    },
    visual: LessonVocabularyVisual.divideByOne,
  ),
  LessonVocabulary(
    word: '0をわる',
    reading: 'ぜろを わる',
    explanation: '0こを何人かで分けることです。もらう数は0こです。',
    translations: {
      AppLanguage.portuguese: 'dividir 0 por um número',
      AppLanguage.tagalog: 'hatiin ang 0 sa bilang ng tao',
      AppLanguage.vietnamese: 'chia 0 cho một số người',
    },
    visual: LessonVocabularyVisual.zeroItems,
  ),
  LessonVocabulary(
    word: '0ではわれない',
    reading: 'ぜろでは われない',
    explanation: '分ける人が0人なので、分けることはできません。',
    translations: {
      AppLanguage.portuguese: 'não dá para dividir por 0',
      AppLanguage.tagalog: 'hindi maaaring hatiin sa 0',
      AppLanguage.vietnamese: 'không thể chia cho 0',
    },
    visual: LessonVocabularyVisual.divideByZero,
  ),
];

const remainderBasicLessonVocabulary = [
  LessonVocabulary(
    word: 'あまり',
    reading: 'あまり',
    explanation: '分けたあとに残る数です。',
    translations: {
      AppLanguage.portuguese: 'resto / sobra',
      AppLanguage.tagalog: 'sobra / natira',
      AppLanguage.vietnamese: 'số dư',
    },
    visual: LessonVocabularyVisual.remainder,
  ),
  LessonVocabulary(
    word: 'わる数',
    reading: 'わる かず',
    explanation: '何こずつ、または何人で分けるかを表す数です。',
    translations: {
      AppLanguage.portuguese: 'divisor',
      AppLanguage.tagalog: 'divisor',
      AppLanguage.vietnamese: 'số chia',
    },
    visual: LessonVocabularyVisual.divisor,
  ),
  LessonVocabulary(
    word: 'わられる数',
    reading: 'わられる かず',
    explanation: 'はじめにある全部の数です。',
    translations: {
      AppLanguage.portuguese: 'número que será dividido',
      AppLanguage.tagalog: 'bilang na hinahati',
      AppLanguage.vietnamese: 'số bị chia',
    },
    visual: LessonVocabularyVisual.dividend,
  ),
  LessonVocabulary(
    word: 'わりきれる',
    reading: 'わりきれる',
    explanation: 'あまりが出ないで、ぴったり分けられることです。',
    translations: {
      AppLanguage.portuguese: 'dividir sem resto',
      AppLanguage.tagalog: 'mahati nang walang sobra',
      AppLanguage.vietnamese: 'chia hết',
    },
    visual: LessonVocabularyVisual.equalGroups,
  ),
];

const remainderContextLessonVocabulary = [
  LessonVocabulary(
    word: '必要',
    reading: 'ひつよう',
    explanation: 'なくてはならないことです。',
    translations: {
      AppLanguage.portuguese: 'necessário',
      AppLanguage.tagalog: 'kailangan',
      AppLanguage.vietnamese: 'cần thiết',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '1つ増やす',
    reading: 'ひとつ ふやす',
    explanation: '数や量を1つ多くすることです。',
    translations: {
      AppLanguage.portuguese: 'aumentar mais 1',
      AppLanguage.tagalog: 'dagdagan ng isa',
      AppLanguage.vietnamese: 'thêm 1',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '使わない',
    reading: 'つかわない',
    explanation: 'そのものを使わないことです。',
    translations: {
      AppLanguage.portuguese: 'não usar / não contar',
      AppLanguage.tagalog: 'hindi gamitin / hindi bilangin',
      AppLanguage.vietnamese: 'không dùng / không tính',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '場面',
    reading: 'ばめん',
    explanation: 'そこで起きていることや、そのときの様子です。',
    translations: {
      AppLanguage.portuguese: 'situação',
      AppLanguage.tagalog: 'sitwasyon',
      AppLanguage.vietnamese: 'tình huống',
    },
    visual: LessonVocabularyVisual.none,
  ),
];

const zeroOneDivisionVocabularyEntries = [
  ...equalShareVocabularyEntries,
  VocabularyEntry(
    term: '1でわる',
    reading: 'いちでわる',
    simpleJapanese: '1人で分けることです。',
    translations: {
      AppLanguage.portuguese: 'dividir por 1',
      AppLanguage.tagalog: 'hatiin sa 1',
      AppLanguage.vietnamese: 'chia cho 1',
    },
    exampleSentence: '6 ÷ 1 は、1でわる式です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '0をわる',
    reading: 'ぜろをわる',
    simpleJapanese: '0こを何人かで分けることです。',
    translations: {
      AppLanguage.portuguese: 'dividir 0 por um número',
      AppLanguage.tagalog: 'hatiin ang 0 sa bilang ng tao',
      AppLanguage.vietnamese: 'chia 0 cho một số người',
    },
    exampleSentence: '0 ÷ 3 は、0をわる式です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '0ではわれない',
    reading: 'ぜろではわれない',
    simpleJapanese: '0人には分けられない、ということです。',
    translations: {
      AppLanguage.portuguese: 'não dá para dividir por 0',
      AppLanguage.tagalog: 'hindi maaaring hatiin sa 0',
      AppLanguage.vietnamese: 'không thể chia cho 0',
    },
    exampleSentence: '6 ÷ 0 はできません。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'もとの数',
    reading: 'もとのかず',
    simpleJapanese: 'はじめにあった数です。',
    translations: {
      AppLanguage.portuguese: 'número original',
      AppLanguage.tagalog: 'orihinal na bilang',
      AppLanguage.vietnamese: 'số ban đầu',
    },
    exampleSentence: '1でわると、答えはもとの数になります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '配るもの',
    reading: 'くばるもの',
    simpleJapanese: '分けるものです。',
    translations: {
      AppLanguage.portuguese: 'coisas para distribuir',
      AppLanguage.tagalog: 'bagay na ipapamahagi',
      AppLanguage.vietnamese: 'đồ để chia',
    },
    exampleSentence: '配るものがないので、みんな0こです。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'できません',
    reading: 'できません',
    simpleJapanese: 'することができない、という意味です。',
    translations: {
      AppLanguage.portuguese: 'não é possível',
      AppLanguage.tagalog: 'hindi puwede',
      AppLanguage.vietnamese: 'không thể',
    },
    exampleSentence: '0ではわることはできません。',
    category: 'school_japanese',
  ),
];

const measureDivisionVocabularyEntries = [
  ...equalShareVocabularyEntries,
  VocabularyEntry(
    term: 'クッキー',
    reading: 'くっきー',
    simpleJapanese: 'おかしの名前です。',
    translations: {
      AppLanguage.portuguese: 'biscoito',
      AppLanguage.tagalog: 'cookie / biskwit',
      AppLanguage.vietnamese: 'bánh quy',
    },
    exampleSentence: '8このクッキーがあります。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: 'あめ',
    reading: 'あめ',
    simpleJapanese: '小さいおかしです。',
    translations: {
      AppLanguage.portuguese: 'bala / doce',
      AppLanguage.tagalog: 'kendi',
      AppLanguage.vietnamese: 'kẹo',
    },
    exampleSentence: '12このあめを分けます。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: 'カード',
    reading: 'かーど',
    simpleJapanese: '紙の小さい札のようなものです。',
    translations: {
      AppLanguage.portuguese: 'cartão',
      AppLanguage.tagalog: 'card',
      AppLanguage.vietnamese: 'thẻ',
    },
    exampleSentence: '15まいのカードを分けます。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: 'ビー玉',
    reading: 'びーだま',
    simpleJapanese: '小さい丸い玉です。',
    translations: {
      AppLanguage.portuguese: 'bolinha de gude',
      AppLanguage.tagalog: 'holen',
      AppLanguage.vietnamese: 'viên bi',
    },
    exampleSentence: '18このビー玉を分けます。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: 'シール',
    reading: 'しーる',
    simpleJapanese: 'はって使うものです。',
    translations: {
      AppLanguage.portuguese: 'adesivo',
      AppLanguage.tagalog: 'sticker',
      AppLanguage.vietnamese: 'nhãn dán',
    },
    exampleSentence: '24このシールを分けます。',
    category: 'noun',
  ),
  VocabularyEntry(
    term: 'まとまり',
    reading: 'まとまり',
    simpleJapanese: 'いくつかを集めたグループ',
    translations: {
      AppLanguage.portuguese: 'grupo',
      AppLanguage.tagalog: 'grupo',
      AppLanguage.vietnamese: 'nhóm',
    },
    exampleSentence: '2こずつのまとまりを作ります。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'まい',
    reading: 'まい',
    simpleJapanese: '紙のように薄いものを数える言い方です。',
    translations: {
      AppLanguage.portuguese: 'contador para coisas finas',
      AppLanguage.tagalog: 'bilang para manipis na bagay',
      AppLanguage.vietnamese: 'từ đếm vật mỏng',
    },
    exampleSentence: '15まいのカードがあります。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '何人',
    reading: 'なんにん',
    simpleJapanese: '人の数を聞く言葉',
    translations: {
      AppLanguage.portuguese: 'quantas pessoas',
      AppLanguage.tagalog: 'ilang tao',
      AppLanguage.vietnamese: 'bao nhiêu người',
    },
    exampleSentence: '何人に分けられますか。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: '何こずつ',
    reading: 'なんこずつ',
    simpleJapanese: '1人に何こずつかを聞く言葉',
    translations: {
      AppLanguage.portuguese: 'quantos para cada pessoa',
      AppLanguage.tagalog: 'tig-ilan para sa bawat tao',
      AppLanguage.vietnamese: 'mỗi người bao nhiêu cái',
    },
    exampleSentence: '1人に何こずつ分けますか。',
    category: 'math_language',
  ),
];

String equalSharePersonLabel(int index, AppLanguage language) {
  switch (language) {
    case AppLanguage.japanese:
      return '';
    case AppLanguage.portuguese:
      return 'Pessoa ${index + 1}';
    case AppLanguage.tagalog:
      return 'Tao ${index + 1}';
    case AppLanguage.vietnamese:
      return 'Người ${index + 1}';
  }
}
