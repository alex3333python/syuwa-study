// Regenerates subset TTFs used by the web build (run after adding new UI text).
// Requires: pip install fonttools brotli  (pyftsubset on PATH)
//
// Usage: dart run tool/subset_fonts.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  final chars = await _collectCharacters();
  stdout.writeln('Subsetting fonts for ${chars.length} unique characters…');

  final subsetDir = Directory('assets/fonts/gen_interface_jp/subset');
  subsetDir.createSync(recursive: true);

  const fonts = [
    'standard/GenInterfaceJP-Regular.ttf',
    'standard/GenInterfaceJP-SemiBold.ttf',
    'standard/GenInterfaceJP-Bold.ttf',
    'display/GenInterfaceJPDisplay-Regular.ttf',
    'display/GenInterfaceJPDisplay-SemiBold.ttf',
    'display/GenInterfaceJPDisplay-Bold.ttf',
  ];

  for (final font in fonts) {
    final src = File('assets/fonts/gen_interface_jp/$font');
    final dst = File('${subsetDir.path}/$font');
    dst.parent.createSync(recursive: true);

    final result = await Process.run('pyftsubset', [
      src.path,
      '--output-file=${dst.path}',
      '--text=$chars',
      '--layout-features=*',
      '--glyph-names',
      '--symbol-cmap',
      '--legacy-cmap',
      '--notdef-glyph',
      '--notdef-outline',
      '--recalc-bounds',
      '--recalc-timestamp',
      '--recommended-glyphs',
    ]);

    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      exit(result.exitCode);
    }
    stdout.writeln('  $font');
  }

  stdout.writeln('Done.');
}

Future<String> _collectCharacters() async {
  final chars = <int>{};

  void addString(String s) {
    for (final rune in s.runes) {
      chars.add(rune);
    }
  }

  final libDir = Directory('lib');
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final text = await entity.readAsString();
    for (final match in RegExp(r"'([^'\\]|\\.)*'|\"([^\"\\]|\\.)*\"").allMatches(text)) {
      addString(match.group(0)!.substring(1, match.group(0)!.length - 1));
    }
  }

  // Hiragana, katakana, half-width katakana, basic Latin.
  for (var cp = 0x3040; cp <= 0x30ff; cp++) {
    chars.add(cp);
  }
  for (var cp = 0xff00; cp <= 0xffef; cp++) {
    chars.add(cp);
  }
  for (var cp = 0x20; cp <= 0x7e; cp++) {
    chars.add(cp);
  }

  addString('。、・「」『』（）％：？！…ー〜');

  final sorted = chars.toList()..sort();
  return String.fromCharCodes(sorted);
}
