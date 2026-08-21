final _kanjiChar = RegExp(r'[一-龯々〆]');
final _leadingDigits = RegExp(r'^[0-9０-９]+');

class KanjiRubySpan {
  final String text;
  final String? ruby;

  const KanjiRubySpan(this.text, [this.ruby]);
}

/// Markup with `{漢字|よみ}` only on kanji; okurigana is left as plain text.
String kanjiOnlyRubyMarkup(String base, String reading) {
  final buffer = StringBuffer();
  for (final span in splitKanjiRuby(base, reading)) {
    if (span.ruby == null || span.ruby!.isEmpty) {
      buffer.write(span.text);
    } else {
      buffer.write('{${span.text}|${span.ruby}}');
    }
  }
  return buffer.toString();
}

/// Puts furigana on kanji only. Okurigana and other hiragana stay bare.
List<KanjiRubySpan> splitKanjiRuby(String base, String reading) {
  final ruby = reading.replaceAll(' ', '');
  if (base.isEmpty) return const [];
  if (!_kanjiChar.hasMatch(base) || ruby.isEmpty || ruby == base) {
    return [KanjiRubySpan(base)];
  }

  final lead = _leadingDigits.firstMatch(base);
  if (lead != null && lead.end < base.length) {
    final numbered = _splitNumberedCounter(base, ruby, lead.end);
    if (numbered != null) return numbered;
  }

  final baseChars = _chars(base);
  final spans = <KanjiRubySpan>[];
  var rubyCursor = 0;

  var index = 0;
  while (index < baseChars.length) {
    if (_kanjiChar.hasMatch(baseChars[index])) {
      var end = index + 1;
      while (end < baseChars.length && _kanjiChar.hasMatch(baseChars[end])) {
        end++;
      }
      final kanji = baseChars.sublist(index, end).join();
      final following = StringBuffer();
      var look = end;
      while (look < baseChars.length && !_kanjiChar.hasMatch(baseChars[look])) {
        following.write(baseChars[look]);
        look++;
      }
      final remaining = rubyCursor >= ruby.length
          ? ''
          : ruby.substring(rubyCursor);
      final follow = following.toString();
      final splitAt = follow.isEmpty ? -1 : remaining.indexOf(follow);
      final kanjiReading = splitAt < 0
          ? remaining
          : remaining.substring(0, splitAt);
      if (kanjiReading.isEmpty) {
        spans.add(KanjiRubySpan(kanji));
      } else {
        spans.add(KanjiRubySpan(kanji, kanjiReading));
        rubyCursor += kanjiReading.length;
      }
      index = end;
    } else {
      var end = index + 1;
      while (end < baseChars.length && !_kanjiChar.hasMatch(baseChars[end])) {
        end++;
      }
      final other = baseChars.sublist(index, end).join();
      if (ruby.startsWith(other, rubyCursor)) {
        rubyCursor += other.length;
      }
      spans.add(KanjiRubySpan(other));
      index = end;
    }
  }

  return spans;
}

List<KanjiRubySpan>? _splitNumberedCounter(
  String base,
  String ruby,
  int digitEnd,
) {
  final digits = base.substring(0, digitEnd);
  final rest = base.substring(digitEnd);
  final ascii = _asciiDigits(digits);
  if (rest.isEmpty || !_kanjiChar.hasMatch(rest)) return null;

  if (ascii == '1' && rest.startsWith('人') && ruby.startsWith('ひとり')) {
    return [
      KanjiRubySpan('$digits人', 'ひとり'),
      ...splitKanjiRuby(rest.substring(1), ruby.substring('ひとり'.length)),
    ];
  }
  if (ascii == '2' && rest.startsWith('人') && ruby.startsWith('ふたり')) {
    return [
      KanjiRubySpan('$digits人', 'ふたり'),
      ...splitKanjiRuby(rest.substring(1), ruby.substring('ふたり'.length)),
    ];
  }
  if (rest.startsWith('人') && ruby.endsWith('にん')) {
    return [
      KanjiRubySpan(digits),
      const KanjiRubySpan('人', 'にん'),
      ...splitKanjiRuby(rest.substring(1), ruby.substring(0, ruby.length - 2)),
    ];
  }
  return null;
}

String _asciiDigits(String value) {
  const fullWidth = '０１２３４５６７８９';
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final index = fullWidth.indexOf(char);
    buffer.write(index >= 0 ? '$index' : char);
  }
  return buffer.toString();
}

List<String> _chars(String value) {
  return value.runes.map(String.fromCharCode).toList(growable: false);
}
