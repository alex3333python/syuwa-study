import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_syuwa/data/learning_language_support.dart';
import 'package:flutter_syuwa/services/japanese_speech_text.dart';

void main() {
  test('same-number sharing uses かず and なんこ, not すう or なに', () {
    expect(
      applyLearningRuby('3人で同じ数ずつ分けると、1人分は何こになりますか。'),
      allOf(contains('{同|おな}'), contains('{数|かず}')),
    );
    expect(
      applyLearningRuby('3人で同じ数ずつ分けると、1人分は何こになりますか。'),
      contains('{何|なん}こ'),
    );
    expect(
      applyLearningRuby('同じ数ずつ分けてみよう'),
      isNot(contains('すう')),
    );
    expect(
      applyLearningRuby('1人分は何こになりますか。'),
      isNot(contains('なに')),
    );
    expect(applyLearningRuby('9人'), '9{人|にん}');
    expect(applyLearningRuby('1人'), '{1人|ひとり}');
  });

  test('counter 何 uses なん, while 数字 keeps すうじ', () {
    expect(applyLearningRuby('何人に分けられますか。'), contains('{何人|なんにん}'));
    expect(applyLearningRuby('車は何台必要ですか。'), contains('{何台|なんだい}'));
    expect(applyLearningRuby('答えは何ですか。'), contains('{何|なん}ですか'));
    expect(applyLearningRuby('数字で表します。'), contains('{数字|すうじ}'));
    expect(applyLearningRuby('数字で表します。'), isNot(contains('{数|かず}字')));
  });

  test('何 plus metric unit keeps ruby only on 何', () {
    expect(applyLearningRuby('何cm長いですか。'), '{何|なん}cm{長|なが}いですか。');
    expect(applyLearningRuby('何mですか。'), '{何|なん}mですか。');
    expect(applyLearningRuby('何kgですか。'), '{何|なん}kgですか。');
    expect(applyLearningRuby('何gですか。'), '{何|なん}gですか。');
    expect(applyLearningRuby('何kmですか。'), '{何|なん}kmですか。');
    expect(applyLearningRuby('何tですか。'), '{何|なん}tですか。');
    expect(
      applyLearningRuby('より何cm長い'),
      isNot(contains('なんセンチメートル')),
    );
  });

  test('okurigana is not wrapped with furigana', () {
    expect(applyLearningRuby('分けてみよう'), '{分|わ}けてみよう');
    expect(applyLearningRuby('使って見つけられます'), '{使|つか}って{見|み}つけられます');
    expect(applyLearningRuby('答えを作る'), '{答|こた}えを{作|つく}る');
  });

  test('TTS reads sharing sentences with かず and なんこ', () {
    expect(
      JapaneseSpeechText.prepare('3人で同じ数ずつ分けると、1人分は何こになりますか。'),
      allOf(contains('かず'), contains('なんこ'), isNot(contains('なにこ'))),
    );
    expect(
      JapaneseSpeechText.prepare('12このクッキーを、3人に同じ数ずつ分けてみよう。'),
      allOf(contains('わけてみよう'), contains('かずずつ')),
    );
    expect(
      JapaneseSpeechText.prepare(
        '{わり算|わりざん}の{答え|こたえ}は、{かけ算|かけざん}を{使って|つかって}{見つけられます|みつけられます}。',
      ),
      'わりざんのこたえは、かけざんをつかってみつけられます。',
    );
  });
}
