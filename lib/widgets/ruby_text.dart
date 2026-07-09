import 'package:flutter/material.dart';

class RubyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final TextAlign textAlign;

  const RubyText({
    super.key,
    required this.text,
    this.style,
    this.rubyStyle,
    this.textAlign = TextAlign.start,
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
        parts.add(
          _RubyPart(
            base: content.substring(0, separator),
            ruby: content.substring(separator + 1),
          ),
        );
      }
      index = end + 1;
    }

    return parts;
  }

  void _addPlainText(List<_RubyPart> parts, String value) {
    for (final rune in value.runes) {
      parts.add(_RubyPart(base: String.fromCharCode(rune)));
    }
  }
}

class _RubyLine extends StatelessWidget {
  final List<_RubyPart> parts;
  final TextStyle style;
  final TextStyle rubyStyle;
  final WrapAlignment alignment;

  const _RubyLine({
    required this.parts,
    required this.style,
    required this.rubyStyle,
    required this.alignment,
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
          _RubyPiece(part: part, style: style, rubyStyle: rubyStyle),
      ],
    );
  }
}

class _RubyPiece extends StatelessWidget {
  final _RubyPart part;
  final TextStyle style;
  final TextStyle rubyStyle;

  const _RubyPiece({
    required this.part,
    required this.style,
    required this.rubyStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (part.ruby == null) {
      return Padding(
        padding: EdgeInsets.only(top: (rubyStyle.fontSize ?? 8) + 2),
        child: Text(part.base, style: style),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(part.ruby!, style: rubyStyle, textAlign: TextAlign.center),
        const SizedBox(height: 1),
        Text(part.base, style: style, textAlign: TextAlign.center),
      ],
    );
  }
}

class _RubyPart {
  final String base;
  final String? ruby;

  const _RubyPart({required this.base, this.ruby});
}
