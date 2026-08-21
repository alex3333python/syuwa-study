import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_syuwa/data/learning_language_support.dart';
import 'package:flutter_syuwa/services/japanese_speech_text.dart';

void main() {
  test('same-number sharing uses かず and なんこ, not すう or なに', () {
    expect(
      applyLearningRuby('3人で同じ数ずつ分けると、1人分は何こになりますか。'),
      contains('{同じ数ずつ|おなじ かずずつ}'),
    );
    expect(
      applyLearningRuby('3人で同じ数ずつ分けると、1人分は何こになりますか。'),
      contains('{何こ|なんこ}'),
    );
    expect(
      applyLearningRuby('同じ数ずつ分けてみよう'),
      isNot(contains('すう')),
    );
    expect(
      applyLearningRuby('1人分は何こになりますか。'),
      isNot(contains('なに')),
    );
  });

  test('counter 何 uses なん, while 数字 keeps すうじ', () {
    expect(applyLearningRuby('何人に分けられますか。'), contains('{何人|なんにん}'));
    expect(applyLearningRuby('車は何台必要ですか。'), contains('{何台|なんだい}'));
    expect(applyLearningRuby('答えは何ですか。'), contains('{何ですか|なんですか}'));
    expect(applyLearningRuby('数字で表します。'), contains('{数字|すうじ}'));
    expect(applyLearningRuby('数字で表します。'), isNot(contains('{数|かず}字')));
  });

  test('TTS reads sharing sentences with かず and なんこ', () {
    expect(
      JapaneseSpeechText.prepare('3人で同じ数ずつ分けると、1人分は何こになりますか。'),
      allOf(contains('かず'), contains('なんこ'), isNot(contains('なにこ'))),
    );
  });
}
