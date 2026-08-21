import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_syuwa/data/kanji_ruby.dart';

void main() {
  test('okurigana does not receive ruby', () {
    final share = splitKanjiRuby('分けてみよう', 'わけてみよう');
    expect(share.map((span) => '${span.text}:${span.ruby}').toList(), [
      '分:わ',
      'けてみよう:null',
    ]);

    final use = splitKanjiRuby('使って', 'つかって');
    expect(use.map((span) => '${span.text}:${span.ruby}').toList(), [
      '使:つか',
      'って:null',
    ]);

    final make = splitKanjiRuby('作る', 'つくる');
    expect(make.map((span) => '${span.text}:${span.ruby}').toList(), [
      '作:つく',
      'る:null',
    ]);

    final answer = splitKanjiRuby('答え', 'こたえ');
    expect(answer.map((span) => '${span.text}:${span.ruby}').toList(), [
      '答:こた',
      'え:null',
    ]);

    final find = splitKanjiRuby('見つけられます', 'みつけられます');
    expect(find.map((span) => '${span.text}:${span.ruby}').toList(), [
      '見:み',
      'つけられます:null',
    ]);
  });

  test('markup keeps furigana on kanji only', () {
    expect(kanjiOnlyRubyMarkup('分けてみよう', 'わけてみよう'), '{分|わ}けてみよう');
    expect(kanjiOnlyRubyMarkup('使って', 'つかって'), '{使|つか}って');
    expect(kanjiOnlyRubyMarkup('作る', 'つくる'), '{作|つく}る');
    expect(kanjiOnlyRubyMarkup('答え', 'こたえ'), '{答|こた}え');
    expect(kanjiOnlyRubyMarkup('見つけられます', 'みつけられます'), '{見|み}つけられます');
  });

  test('numbered people keep にん on 人, and 1人 as ひとり', () {
    expect(kanjiOnlyRubyMarkup('1人', 'ひとり'), '{1人|ひとり}');
    expect(kanjiOnlyRubyMarkup('1人分', 'ひとりぶん'), '{1人|ひとり}{分|ぶん}');
    expect(kanjiOnlyRubyMarkup('2人', 'ふたり'), '{2人|ふたり}');
    expect(kanjiOnlyRubyMarkup('9人', 'きゅうにん'), '9{人|にん}');
    expect(kanjiOnlyRubyMarkup('3人', 'さんにん'), '3{人|にん}');
  });

  test('same-number phrase keeps かず on 数 only', () {
    final spans = splitKanjiRuby('同じ数ずつ', 'おなじかずずつ');
    expect(spans.map((span) => '${span.text}:${span.ruby}').toList(), [
      '同:おな',
      'じ:null',
      '数:かず',
      'ずつ:null',
    ]);
  });
}
