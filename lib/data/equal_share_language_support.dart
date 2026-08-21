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
    return lookupNative(native, language);
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
    return lookupNative(native, language);
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
    return lookupNative(translations, language);
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
  japanese: 'いちごをお皿に分けてみよう！',
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
    term: 'わられる数',
    reading: 'わられる かず',
    simpleJapanese: 'わり算で、分けるもとの数です。',
    translations: {
      AppLanguage.portuguese: 'dividendo',
      AppLanguage.tagalog: 'dividend',
      AppLanguage.vietnamese: 'số bị chia',
    },
    exampleSentence: '6 ÷ 3 の6は、わられる数です。',
    category: 'math_language',
  ),
  VocabularyEntry(
    term: 'わる数',
    reading: 'わる かず',
    simpleJapanese: 'わり算で、何人に分けるかを表す数です。',
    translations: {
      AppLanguage.portuguese: 'divisor',
      AppLanguage.tagalog: 'divisor',
      AppLanguage.vietnamese: 'số chia',
    },
    exampleSentence: '6 ÷ 3 の3は、わる数です。',
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
    ruby: 'また、この{式|しき}では、6を「{わられる数|わられる かず}」、2を「{わる数|わる かず}」といいます。',
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
    explanation: '分けたあとにのこる数です。',
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
    word: '長いす',
    reading: 'ながいす',
    explanation: '何人かがいっしょに座れるいすです。',
    translations: {
      AppLanguage.portuguese: 'banco comprido',
      AppLanguage.tagalog: 'mahabang upuan / bangko',
      AppLanguage.vietnamese: 'ghế dài',
    },
    visual: LessonVocabularyVisual.none,
  ),
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

const timeMainLessonVocabulary = [
  LessonVocabulary(
    word: '時こく',
    reading: 'じこく',
    explanation: '時計がさしている、ある1つの時です。',
    translations: {AppLanguage.portuguese: 'horário',
      AppLanguage.tagalog: 'oras / oras ng orasan',
      AppLanguage.vietnamese: 'thời điểm',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '時間',
    reading: 'じかん',
    explanation: 'ある時こくから、別の時こくまでの長さです。',
    translations: {AppLanguage.portuguese: 'tempo / duração',
      AppLanguage.tagalog: 'oras / tagal',
      AppLanguage.vietnamese: 'thời gian / khoảng thời gian',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '前',
    reading: 'まえ',
    explanation: '時計を戻して考えるときに使います。',
    translations: {AppLanguage.portuguese: 'antes',
      AppLanguage.tagalog: 'bago',
      AppLanguage.vietnamese: 'trước',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '後',
    reading: 'あと / ご',
    explanation: '時計を進めて考えるときに使います。',
    translations: {AppLanguage.portuguese: 'depois',
      AppLanguage.tagalog: 'pagkatapos',
      AppLanguage.vietnamese: 'sau',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '出発',
    reading: 'しゅっぱつ',
    explanation: 'ある場所を出ることです。',
    translations: {AppLanguage.portuguese: 'partida / sair',
      AppLanguage.tagalog: 'alis / umalis',
      AppLanguage.vietnamese: 'xuất phát / rời đi',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '到着',
    reading: 'とうちゃく',
    explanation: '行き先につくことです。',
    translations: {AppLanguage.portuguese: 'chegada',
      AppLanguage.tagalog: 'dating',
      AppLanguage.vietnamese: 'đến nơi',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '午前',
    reading: 'ごぜん',
    explanation: '夜中の12時から、正午までの時こくにつける言葉です。',
    translations: {AppLanguage.portuguese: 'da manhã / a.m.',
      AppLanguage.tagalog: 'umaga / a.m.',
      AppLanguage.vietnamese: 'buổi sáng / a.m.',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '午後',
    reading: 'ごご',
    explanation: '正午をすぎたあとの時こくにつける言葉です。',
    translations: {AppLanguage.portuguese: 'da tarde / p.m.',
      AppLanguage.tagalog: 'hapon / p.m.',
      AppLanguage.vietnamese: 'buổi chiều / p.m.',},
    visual: LessonVocabularyVisual.none,
  ),
];

const shortTimeLessonVocabulary = [
  LessonVocabulary(
    word: '秒',
    reading: 'びょう',
    explanation: '分より短い時間を表す単位です。',
    translations: {AppLanguage.portuguese: 'segundo',
      AppLanguage.tagalog: 'segundo',
      AppLanguage.vietnamese: 'giây',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '秒針',
    reading: 'びょうしん',
    explanation: '時計で、秒を表す細い針です。',
    translations: {AppLanguage.portuguese: 'ponteiro dos segundos',
      AppLanguage.tagalog: 'segundong kamay ng orasan',
      AppLanguage.vietnamese: 'kim giây',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '1分',
    reading: 'いっぷん',
    explanation: '60秒と同じ長さの時間です。',
    translations: {AppLanguage.portuguese: '1 minuto',
      AppLanguage.tagalog: '1 minuto',
      AppLanguage.vietnamese: '1 phút',},
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '短い時間',
    reading: 'みじかい じかん',
    explanation: '少しだけの時間です。',
    translations: {AppLanguage.portuguese: 'tempo curto',
      AppLanguage.tagalog: 'maikling oras',
      AppLanguage.vietnamese: 'thời gian ngắn',},
    visual: LessonVocabularyVisual.none,
  ),
];

const lengthMeasureLessonVocabulary = [
  LessonVocabulary(
    word: '長さ',
    reading: 'ながさ',
    explanation: 'もののはしからはしまでの大きさです。',
    translations: {
      AppLanguage.portuguese: 'comprimento',
      AppLanguage.tagalog: 'haba',
      AppLanguage.vietnamese: 'độ dài',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: 'はかる',
    reading: 'はかる',
    explanation: '長さや重さなどを調べることです。',
    translations: {
      AppLanguage.portuguese: 'medir',
      AppLanguage.tagalog: 'sukatin',
      AppLanguage.vietnamese: 'đo',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '目もり',
    reading: 'めもり',
    explanation: 'ものさしやまきじゃくについている、小さなしるしです。',
    translations: {
      AppLanguage.portuguese: 'marca / escala',
      AppLanguage.tagalog: 'marka sa panukat',
      AppLanguage.vietnamese: 'vạch chia',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: 'まきじゃく',
    reading: 'まきじゃく',
    explanation: '長いものや、曲がったところをはかりやすい道具です。',
    translations: {
      AppLanguage.portuguese: 'fita métrica',
      AppLanguage.tagalog: 'metro / tape measure',
      AppLanguage.vietnamese: 'thước dây',
    },
    visual: LessonVocabularyVisual.none,
  ),
];

const kilometerLessonVocabulary = [
  LessonVocabulary(
    word: 'キロメートル',
    reading: 'きろめーとる',
    explanation: '長い道のりを表すときに使う単位です。1kmは1000mです。',
    translations: {
      AppLanguage.portuguese: 'quilômetro',
      AppLanguage.tagalog: 'kilometro',
      AppLanguage.vietnamese: 'ki-lô-mét',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '道のり',
    reading: 'みちのり',
    explanation: '実際に通る道の長さです。',
    translations: {
      AppLanguage.portuguese: 'caminho / percurso',
      AppLanguage.tagalog: 'haba ng dinaanan',
      AppLanguage.vietnamese: 'quãng đường đi',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: 'きょり',
    reading: 'きょり',
    explanation: '2つの場所の間の長さです。',
    translations: {
      AppLanguage.portuguese: 'distância',
      AppLanguage.tagalog: 'distansya',
      AppLanguage.vietnamese: 'khoảng cách',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '比べる',
    reading: 'くらべる',
    explanation: 'どちらが長いか、同じ単位にして見ます。',
    translations: {
      AppLanguage.portuguese: 'comparar',
      AppLanguage.tagalog: 'ihambing',
      AppLanguage.vietnamese: 'so sánh',
    },
    visual: LessonVocabularyVisual.none,
  ),
];

const weightGramKgLessonVocabulary = [
  LessonVocabulary(
    word: '重い',
    reading: 'おもい',
    explanation: '持ったときに、力がたくさんいる感じです。',
    translations: {
      AppLanguage.portuguese: 'pesado',
      AppLanguage.tagalog: 'mabigat',
      AppLanguage.vietnamese: 'nặng',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '軽い',
    reading: 'かるい',
    explanation: '持ったときに、力があまりいらない感じです。',
    translations: {
      AppLanguage.portuguese: 'leve',
      AppLanguage.tagalog: 'magaan',
      AppLanguage.vietnamese: 'nhẹ',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '重さ',
    reading: 'おもさ',
    explanation: 'ものがどれくらい重いかを表します。',
    translations: {
      AppLanguage.portuguese: 'peso',
      AppLanguage.tagalog: 'bigat',
      AppLanguage.vietnamese: 'cân nặng / trọng lượng',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: 'はかり',
    reading: 'はかり',
    explanation: '重さを調べる道具です。',
    translations: {
      AppLanguage.portuguese: 'balança',
      AppLanguage.tagalog: 'timbangan',
      AppLanguage.vietnamese: 'cái cân',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '目もり',
    reading: 'めもり',
    explanation: 'はかりやものさしについている、小さなしるしです。',
    translations: {
      AppLanguage.portuguese: 'marcação / escala',
      AppLanguage.tagalog: 'marka / guhit',
      AppLanguage.vietnamese: 'vạch chia',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: 'キログラム',
    reading: 'きろぐらむ',
    explanation: '重いものの重さを表すときに使う単位です。1kgは1000gです。',
    translations: {
      AppLanguage.portuguese: 'quilograma',
      AppLanguage.tagalog: 'kilogramo',
      AppLanguage.vietnamese: 'ki-lô-gam',
    },
    visual: LessonVocabularyVisual.none,
  ),
];

const weightTonLessonVocabulary = [
  LessonVocabulary(
    word: 'トン',
    reading: 'とん',
    explanation: 'とても重いものを表すときに使う単位です。1tは1000kgです。',
    translations: {
      AppLanguage.portuguese: 'tonelada',
      AppLanguage.tagalog: 'tonelada',
      AppLanguage.vietnamese: 'tấn',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '積む',
    reading: 'つむ',
    explanation: '荷物などを、上や中にのせることです。',
    translations: {
      AppLanguage.portuguese: 'carregar / colocar carga',
      AppLanguage.tagalog: 'ikarga',
      AppLanguage.vietnamese: 'chất lên / xếp lên',
    },
    visual: LessonVocabularyVisual.none,
  ),
  LessonVocabulary(
    word: '単位',
    reading: 'たんい',
    explanation: 'g、kg、tのように、量を表すための言葉です。',
    translations: {
      AppLanguage.portuguese: 'unidade',
      AppLanguage.tagalog: 'yunit',
      AppLanguage.vietnamese: 'đơn vị',
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
    term: '配る',
    reading: 'くばる',
    simpleJapanese: '何人かにものを分けて渡すことです。',
    translations: {
      AppLanguage.portuguese: 'distribuir',
      AppLanguage.tagalog: 'ipamahagi',
      AppLanguage.vietnamese: 'phân phát',
    },
    exampleSentence: '3人にいちごを配ります。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '入れる',
    reading: 'いれる',
    simpleJapanese: 'ものを中に移すことです。',
    translations: {
      AppLanguage.portuguese: 'colocar / pôr dentro',
      AppLanguage.tagalog: 'ilagay sa loob',
      AppLanguage.vietnamese: 'đặt vào trong',
    },
    exampleSentence: 'いちごを皿に入れます。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '答え',
    reading: 'こたえ',
    simpleJapanese: '問題を考えて出す数です。',
    translations: {
      AppLanguage.portuguese: 'resposta',
      AppLanguage.tagalog: 'sagot',
      AppLanguage.vietnamese: 'đáp án',
    },
    exampleSentence: '答えは0です。',
    category: 'school_japanese',
  ),
  VocabularyEntry(
    term: '何',
    reading: 'なん',
    simpleJapanese: '分からないものや数を聞く言葉です。',
    translations: {
      AppLanguage.portuguese: 'o que / qual',
      AppLanguage.tagalog: 'ano / alin',
      AppLanguage.vietnamese: 'gì / nào',
    },
    exampleSentence: '答えは何ですか。',
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
    term: '正しい',
    reading: 'ただしい',
    simpleJapanese: '合っていて、まちがっていないことです。',
    translations: {
      AppLanguage.portuguese: 'correto / certo',
      AppLanguage.tagalog: 'tama',
      AppLanguage.vietnamese: 'đúng',
    },
    exampleSentence: '正しい式を選びます。',
    category: 'school_japanese',
  ),
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
