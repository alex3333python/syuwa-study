// Strips bundled fonts from pubspec.yaml for faster Flutter Web first load.
// iPad Safari uses Hiragino Sans via CSS when fonts are not bundled.
//
// Usage (CI / release web build only):
//   dart run tool/prepare_web_build.dart
//   flutter pub get
//   flutter build web ...

import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml not found');
    exit(1);
  }

  final lines = pubspec.readAsLinesSync();
  final output = <String>[];
  var skippingFonts = false;

  for (final line in lines) {
    if (!skippingFonts && line.startsWith('  fonts:')) {
      skippingFonts = true;
      output.add('  # fonts: omitted for web release build (system fonts on Safari)');
      continue;
    }

    if (skippingFonts) {
      if (line.startsWith('  ') && !line.startsWith('    ') && !line.startsWith('  #')) {
        skippingFonts = false;
        output.add(line);
      }
      continue;
    }

    output.add(line);
  }

  pubspec.writeAsStringSync('${output.join('\n')}\n');
  stdout.writeln('Prepared pubspec.yaml for web build (fonts removed).');
}
