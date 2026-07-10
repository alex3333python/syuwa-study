import '../models/app_language.dart';
import '../models/question.dart';

class SupportLine {
  final String japanese;
  final Map<AppLanguage, String> native;

  const SupportLine({required this.japanese, this.native = const {}});

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

const equalShareProblemLines = [
  SupportLine(
    japanese: 'いちごが6こあります。',
    native: {
      AppLanguage.portuguese: 'Há 6 morangos.',
      AppLanguage.tagalog: 'May 6 na strawberry.',
      AppLanguage.vietnamese: 'Có 6 quả dâu.',
    },
  ),
  SupportLine(
    japanese: '3人で同じ数ずつ分けると、1人分は何こになりますか。',
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
  native: {
    AppLanguage.portuguese: 'Vamos dividir os morangos nos pratos!',
    AppLanguage.tagalog: 'Igalaw natin ang mga strawberry!',
    AppLanguage.vietnamese: 'Hãy chia dâu vào các đĩa!',
  },
);

const equalShareResultLines = [
  SupportLine(
    japanese: '同じ数ずつ分けられたね！',
    native: {
      AppLanguage.portuguese: 'Você conseguiu dividir igualmente!',
      AppLanguage.tagalog: 'Nahati mo nang pantay!',
      AppLanguage.vietnamese: 'Em đã chia đều được rồi!',
    },
  ),
  SupportLine(
    japanese: 'どのお皿にも、いちごが2こずつあるね。',
    native: {
      AppLanguage.portuguese: 'Cada prato tem 2 morangos.',
      AppLanguage.tagalog: 'May tig-2 strawberry sa bawat plato.',
      AppLanguage.vietnamese: 'Mỗi đĩa đều có 2 quả dâu.',
    },
  ),
  SupportLine(
    japanese: 'いちご6こを、3人で同じ数ずつ分けると、1人分は2こになります。',
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
    label: 'ぜんぶの数',
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

const equalShareVocabularyEntries = [
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
    term: '全部の数',
    reading: 'ぜんぶのかず',
    simpleJapanese: 'はじめにある、ぜんぶの数',
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
