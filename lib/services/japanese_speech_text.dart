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

    spoken = _dropDigitsAlreadySpoken(spoken);

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

  static final _digitRun = RegExp(r'[0-9０-９]+');

  /// Avoids "いちひとり" / "きゅうきゅうにん" when a digit sits in front of its own reading.
  static String _dropDigitsAlreadySpoken(String spoken) {
    return spoken.replaceAllMapped(_digitRun, (match) {
      final digits = match.group(0)!;
      final rest = spoken.substring(match.end);
      if (_restAlreadySaysNumber(digits, rest)) {
        return '';
      }
      return digits;
    });
  }

  static bool _restAlreadySaysNumber(String rawDigits, String rest) {
    final digits = _asciiDigits(rawDigits);
    if (digits == '1' &&
        (rest.startsWith('ひとり') || rest.startsWith('ひとつ'))) {
      return true;
    }
    if (digits == '2' &&
        (rest.startsWith('ふたり') || rest.startsWith('ふたつ'))) {
      return true;
    }
    for (final reading in _numberReadings(digits)) {
      if (!rest.startsWith(reading)) continue;
      // "2にん" must stay; "に" is only the start of the counter にん.
      if (reading == 'に' && rest.startsWith('にん')) continue;
      return true;
    }
    return false;
  }

  static String _asciiDigits(String value) {
    const fullWidth = '０１２３４５６７８９';
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final index = fullWidth.indexOf(char);
      buffer.write(index >= 0 ? '$index' : char);
    }
    return buffer.toString();
  }

  static List<String> _numberReadings(String digits) {
    final n = int.tryParse(digits);
    if (n == null || n < 0 || n > 999) return const [];
    final readings = <String>{
      _cardinal(n, one: 'いち', four: 'よん', seven: 'なな', eight: 'はち', nine: 'きゅう'),
      _cardinal(n, one: 'いっ', four: 'よ', seven: 'しち', eight: 'はっ', nine: 'く'),
      _cardinal(n, one: 'いち', four: 'し', seven: 'しち', eight: 'はち', nine: 'きゅう'),
    }..removeWhere((reading) => reading.isEmpty);
    return readings.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
  }

  static String _cardinal(
    int n, {
    required String one,
    required String four,
    required String seven,
    required String eight,
    required String nine,
  }) {
    String ones(int d) {
      switch (d) {
        case 1:
          return one;
        case 2:
          return 'に';
        case 3:
          return 'さん';
        case 4:
          return four;
        case 5:
          return 'ご';
        case 6:
          return 'ろく';
        case 7:
          return seven;
        case 8:
          return eight;
        case 9:
          return nine;
        default:
          return '';
      }
    }

    if (n == 0) return 'ゼロ';
    if (n < 10) return ones(n);
    if (n < 100) {
      final tens = n ~/ 10;
      final onesDigit = n % 10;
      final ten = tens == 1 ? 'じゅう' : '${ones(tens)}じゅう';
      return onesDigit == 0 ? ten : '$ten${ones(onesDigit)}';
    }
    if (n < 1000) {
      final hundreds = n ~/ 100;
      final rest = n % 100;
      String hundred;
      switch (hundreds) {
        case 1:
          hundred = 'ひゃく';
          break;
        case 3:
          hundred = 'さんびゃく';
          break;
        case 6:
          hundred = 'ろっぴゃく';
          break;
        case 8:
          hundred = 'はっぴゃく';
          break;
        default:
          hundred = '${ones(hundreds)}ひゃく';
      }
      return rest == 0 ? hundred : '$hundred${_cardinal(rest, one: one, four: four, seven: seven, eight: eight, nine: nine)}';
    }
    return '';
  }
}
