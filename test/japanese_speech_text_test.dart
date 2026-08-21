import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_syuwa/services/japanese_speech_text.dart';

void main() {
  test('reads division remainder formulas in Japanese', () {
    expect(
      JapaneseSpeechText.prepare('7 ÷ 3 = 2 あまり 1'),
      '7 わる 3 は 2 あまり 1',
    );
  });

  test('reads multiplication and units', () {
    expect(
      JapaneseSpeechText.prepare('3 × 4 = 12'),
      '3 かける 4 は 12',
    );
    expect(JapaneseSpeechText.prepare('8cm'), '8センチメートル');
    expect(JapaneseSpeechText.prepare('1 kg'), '1キログラム');
    expect(JapaneseSpeechText.prepare('1000m'), '1000メートル');
  });

  test('reads clock times and padded stopwatch times', () {
    expect(JapaneseSpeechText.prepare('8:10'), '8時10分');
    expect(JapaneseSpeechText.prepare('午前8:10'), '午前8時10分');
    expect(JapaneseSpeechText.prepare('01:20'), '1分20秒');
  });

  test('uses ruby readings and dictionary readings for TTS', () {
    expect(
      JapaneseSpeechText.prepare('{午前|ごぜん}8時'),
      'ごぜん8時',
    );
    expect(
      JapaneseSpeechText.fromCue(
        japaneseText: '長いす',
        spokenText: 'ながいす',
      ),
      'ながいす',
    );
    expect(JapaneseSpeechText.cleanReading('あと / ご'), 'あと、ご');
  });
}
