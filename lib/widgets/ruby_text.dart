import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../models/question.dart';

class RubyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final TextAlign textAlign;
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;

  const RubyText({
    super.key,
    required this.text,
    this.style,
    this.rubyStyle,
    this.textAlign = TextAlign.start,
    this.vocabularyEntries = const [],
    this.language = AppLanguage.japanese,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(style);
    final effectiveRubyStyle = TextStyle(
      fontSize: (effectiveStyle.fontSize ?? 16) * 0.48,
      height: 1.05,
      fontWeight: FontWeight.w700,
      color: effectiveStyle.color?.withValues(alpha: 0.78),
    ).merge(rubyStyle);
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: _crossAxisAlignment,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          _RubyLine(
            parts: _parseRuby(lines[i]),
            style: effectiveStyle,
            rubyStyle: effectiveRubyStyle,
            alignment: _wrapAlignment,
            language: language,
          ),
          if (i < lines.length - 1)
            SizedBox(height: effectiveStyle.fontSize ?? 16),
        ],
      ],
    );
  }

  WrapAlignment get _wrapAlignment {
    switch (textAlign) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        return WrapAlignment.start;
    }
  }

  CrossAxisAlignment get _crossAxisAlignment {
    switch (textAlign) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        return CrossAxisAlignment.start;
    }
  }

  List<_RubyPart> _parseRuby(String line) {
    final parts = <_RubyPart>[];
    var index = 0;

    while (index < line.length) {
      final start = line.indexOf('{', index);
      if (start == -1) {
        _addPlainText(parts, line.substring(index));
        break;
      }

      if (start > index) {
        _addPlainText(parts, line.substring(index, start));
      }

      final end = line.indexOf('}', start + 1);
      if (end == -1) {
        _addPlainText(parts, line.substring(start));
        break;
      }

      final content = line.substring(start + 1, end);
      final separator = content.indexOf('|');
      if (separator <= 0 || separator == content.length - 1) {
        _addPlainText(parts, line.substring(start, end + 1));
      } else {
        final base = content.substring(0, separator);
        parts.add(
          _RubyPart(
            base: base,
            ruby: content.substring(separator + 1),
            entry: _entryFor(base),
          ),
        );
      }
      index = end + 1;
    }

    return parts;
  }

  void _addPlainText(List<_RubyPart> parts, String value) {
    var cursor = 0;
    final entries = vocabularyEntries.toList()
      ..sort((a, b) => b.term.length.compareTo(a.term.length));

    while (cursor < value.length) {
      VocabularyEntry? matched;
      for (final entry in entries) {
        if (entry.term.isEmpty) continue;
        if (value.startsWith(entry.term, cursor)) {
          matched = entry;
          break;
        }
      }

      if (matched != null) {
        parts.add(_RubyPart(base: matched.term, entry: matched));
        cursor += matched.term.length;
        continue;
      }

      final char = String.fromCharCode(value.substring(cursor).runes.first);
      parts.add(_RubyPart(base: char));
      cursor += char.length;
    }
  }

  VocabularyEntry? _entryFor(String base) {
    for (final entry in vocabularyEntries) {
      if (entry.term == base) return entry;
    }
    return null;
  }
}

class _RubyLine extends StatelessWidget {
  final List<_RubyPart> parts;
  final TextStyle style;
  final TextStyle rubyStyle;
  final WrapAlignment alignment;
  final AppLanguage language;

  const _RubyLine({
    required this.parts,
    required this.style,
    required this.rubyStyle,
    required this.alignment,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 0,
      runSpacing: 4,
      children: [
        for (final part in parts)
          _RubyPiece(
            part: part,
            style: style,
            rubyStyle: rubyStyle,
            language: language,
          ),
      ],
    );
  }
}

class _RubyPiece extends StatelessWidget {
  final _RubyPart part;
  final TextStyle style;
  final TextStyle rubyStyle;
  final AppLanguage language;

  const _RubyPiece({
    required this.part,
    required this.style,
    required this.rubyStyle,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final child = part.ruby == null
        ? Padding(
            padding: EdgeInsets.only(top: (rubyStyle.fontSize ?? 8) + 2),
            child: Text(part.base, style: _baseStyle),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(part.ruby!, style: rubyStyle, textAlign: TextAlign.center),
              const SizedBox(height: 1),
              Text(part.base, style: _baseStyle, textAlign: TextAlign.center),
            ],
          );

    if (part.entry == null) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _showVocabularySheet(context, part.entry!),
      child: child,
    );
  }

  TextStyle get _baseStyle {
    if (part.entry == null) return style;
    return style.copyWith(
      color: const Color(0xFF1D4ED8),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF93C5FD),
      backgroundColor: const Color(0xFFEFF6FF),
    );
  }

  void _showVocabularySheet(BuildContext context, VocabularyEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final nativeLabel = language == AppLanguage.japanese
            ? '母国語'
            : language.label;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.term,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                if (entry.reading.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.reading,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _VocabularyBlock(title: 'やさしい日本語', text: entry.simpleJapanese),
                if (language != AppLanguage.japanese) ...[
                  const SizedBox(height: 14),
                  _VocabularyBlock(
                    title: nativeLabel,
                    text: entry.translationFor(language),
                  ),
                ],
                if (entry.exampleSentence.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _VocabularyBlock(title: '例文', text: entry.exampleSentence),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '閉じる',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RubyPart {
  final String base;
  final String? ruby;
  final VocabularyEntry? entry;

  const _RubyPart({required this.base, this.ruby, this.entry});
}

class _VocabularyBlock extends StatelessWidget {
  final String title;
  final String text;

  const _VocabularyBlock({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
