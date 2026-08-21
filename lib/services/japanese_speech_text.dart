import '../data/learning_language_support.dart';

/// Turns on-screen Japanese (including math symbols) into text Japanese TTS can read.
abstract final class JapaneseSpeechText {
  static final _rubyMarkup = RegExp(r'\{([^|{}]+)\|([^{}]+)\}');
  static final _clockTime = RegExp(
    r'(?<!\d)([1-9]|1[0-9]|2[0-3]):([0-5]\d)(?!\d)',
  );
  static final _paddedMinuteSecond = RegExp(
    r'(?<!\d)0(\d):([0-5]\d)(?!\d)',
  );
  static final _unitKm = RegExp(r'(?<=\d)\s*km\b', caseSensitive: false);
  static final _unitKg = RegExp(r'(?<=\d)\s*kg\b', caseSensitive: false);
  static final _unitCm = RegExp(r'(?<=\d)\s*cm\b', caseSensitive: false);
  static final _unitMm = RegExp(r'(?<=\d)\s*mm\b', caseSensitive: false);
  static final _unitM = RegExp(r'(?<=\d)\s*m\b');
  static final _unitG = RegExp(r'(?<=\d)\s*g\b');
  static final _unitT = RegExp(r'(?<=\d)\s*t\b');
  static final _extraSpaces = RegExp(r'\s+');

  static String fromCue({
    required String japaneseText,
    String? spokenText,
  }) {
    final override = spokenText?.trim() ?? '';
    if (override.isNotEmpty) {
      return cleanReading(override);
    }
    return prepare(japaneseText);
  }

  /// Prefer this for dictionary readings so TTS does not guess kanji.
  static String cleanReading(String reading) {
    return reading
        .replaceAll(' / ', '、')
        .replaceAll('/', '、')
        .replaceAll(_extraSpaces, ' ')
        .trim();
  }

  static String prepare(String text) {
    var spoken = applyLearningRuby(text.trim());
    if (spoken.isEmpty) return '';

    spoken = spoken.replaceAllMapped(_rubyMarkup, (match) => match.group(2)!);
    spoken = spoken.replaceAllMapped(
      _paddedMinuteSecond,
      (match) => '${match.group(1)}分${match.group(2)}秒',
    );
    spoken = spoken.replaceAllMapped(
      _clockTime,
      (match) => '${match.group(1)}時${match.group(2)}分',
    );

    spoken = spoken.replaceAll(_unitKm, 'キロメートル');
    spoken = spoken.replaceAll(_unitKg, 'キログラム');
    spoken = spoken.replaceAll(_unitCm, 'センチメートル');
    spoken = spoken.replaceAll(_unitMm, 'ミリメートル');
    spoken = spoken.replaceAll(_unitM, 'メートル');
    spoken = spoken.replaceAll(_unitG, 'グラム');
    spoken = spoken.replaceAll(_unitT, 'トン');

    spoken = spoken
        .replaceAll('÷', ' わる ')
        .replaceAll('×', ' かける ')
        .replaceAll('＋', ' たす ')
        .replaceAll('+', ' たす ')
        .replaceAll('−', ' ひく ')
        .replaceAll('–', ' ひく ')
        .replaceAll('＝', ' は ')
        .replaceAll('=', ' は ')
        .replaceAll('□', 'しかく')
        .replaceAll('→', 'から')
        .replaceAll('・', '、');

    return spoken.replaceAll(_extraSpaces, ' ').trim();
  }
}
