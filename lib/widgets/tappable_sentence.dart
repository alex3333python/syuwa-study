import 'package:flutter/material.dart';

import '../data/glossary.dart';
import '../models/app_language.dart';
import '../theme/app_fonts.dart';
import 'word_popup.dart';

class TappableSentence extends StatelessWidget {
  final String text;
  final AppLanguage language;
  final TextStyle? style;
  final TextAlign textAlign;

  const TappableSentence({
    super.key,
    required this.text,
    required this.language,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    final entries =
        glossaryEntries.values
            .where((entry) => text.contains(entry.word))
            .toList()
          ..sort(
            (a, b) => text.indexOf(a.word).compareTo(text.indexOf(b.word)),
          );

    for (final entry in entries) {
      final index = text.indexOf(entry.word, cursor);
      if (index < 0) continue;

      if (index > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, index)));
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: WordPopup(
            entry: entry,
            language: language,
            child: Text(
              entry.word,
              style: (style ?? const TextStyle()).copyWith(
                color: const Color(0xFF2563EB),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF93C5FD),
              ),
            ),
          ),
        ),
      );
      cursor = index + entry.word.length;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: (style ?? DefaultTextStyle.of(context).style).copyWith(
          fontFamily: AppFonts.interface,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }
}
