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

  String meaningFor(AppLanguage language) {
    if (language == AppLanguage.japanese) {
      return easyJa;
    }
    return native[language] ?? easyJa;
  }
}

const glossaryEntries = {
  '同じ数ずつ': GlossaryEntry(
    word: '同じ数ずつ',
    easyJa: 'ひとり分、または1つのグループの数が同じになること。',
    native: {
      AppLanguage.portuguese: 'A mesma quantidade para cada pessoa ou grupo.',
      AppLanguage.tagalog: 'Pare-parehong bilang para sa bawat tao o grupo.',
      AppLanguage.vietnamese: 'Số lượng bằng nhau cho mỗi người hoặc nhóm.',
    },
  ),
  '残り': GlossaryEntry(
    word: '残り',
    easyJa: 'へったあとに、まだある数。',
    native: {
      AppLanguage.portuguese: 'A quantidade que sobra depois de tirar.',
      AppLanguage.tagalog: 'Bilang na natitira matapos bawasan.',
      AppLanguage.vietnamese: 'Số còn lại sau khi bớt đi.',
    },
  ),
};
