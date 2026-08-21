import '../models/app_language.dart';

class GlossaryEntry {
  final String word;
  final String easyJa;
  final Map<AppLanguage, String> native;

  const GlossaryEntry({
    required this.word,
    required this.easyJa,
    this.native = const {},
  });

  String nativeMeaningFor(AppLanguage language) {
    return lookupNative(native, language);
  }
}

const glossaryEntries = {
  '等しく': GlossaryEntry(
    word: '等しく',
    easyJa: 'どの人も、同じ数になるようにすること。',
    native: {
      AppLanguage.portuguese:
          'igualmente; para todos ficarem com a mesma quantidade',
      AppLanguage.tagalog: 'pantay-pantay; pareho ang bilang para sa bawat isa',
      AppLanguage.vietnamese: 'bằng nhau; để mỗi người có cùng số lượng',
    },
  ),
  '分ける': GlossaryEntry(
    word: '分ける',
    easyJa: 'いくつかの人やグループに、わたすこと。',
    native: {
      AppLanguage.portuguese: 'dividir; distribuir entre pessoas ou grupos',
      AppLanguage.tagalog: 'hatiin; ipamahagi sa mga tao o grupo',
      AppLanguage.vietnamese: 'chia; phân phát cho người hoặc nhóm',
    },
  ),
  'ずつ': GlossaryEntry(
    word: 'ずつ',
    easyJa: 'ひとりに同じ数、または1つのグループに同じ数という意味。',
    native: {
      AppLanguage.portuguese: 'cada; a mesma quantidade para cada um',
      AppLanguage.tagalog: 'bawat isa; parehong bilang sa bawat tao o grupo',
      AppLanguage.vietnamese: 'mỗi; cùng một số lượng cho mỗi người hoặc nhóm',
    },
  ),
};
