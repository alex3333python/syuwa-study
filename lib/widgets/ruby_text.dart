import 'dart:async';

import 'package:flutter/material.dart';

import '../data/audio_cues.dart';
import '../data/kanji_ruby.dart';
import '../data/learning_language_support.dart';
import '../models/app_language.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/favorite_vocabulary_store.dart';
import 'lesson_language_scope.dart';

/// Makes the intent of learning support explicit at each call site.
enum LearningSupportMode { off, rubyOnly, rubyAndDictionary }

class RubyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final TextAlign textAlign;
  final List<VocabularyEntry> vocabularyEntries;
  final AppLanguage language;
  final bool enableLearningSupport;
  final bool learningSupportRubyOnly;
  final LearningSupportMode? learningSupportMode;

  const RubyText({
    super.key,
    required this.text,
    this.style,
    this.rubyStyle,
    this.textAlign = TextAlign.start,
    this.vocabularyEntries = const [],
    this.language = AppLanguage.japanese,
    this.enableLearningSupport = false,
    this.learningSupportRubyOnly = false,
    this.learningSupportMode,
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
    final supportMode = _resolvedLearningSupportMode;
    final supportedText = supportMode == LearningSupportMode.off
        ? text
        : applyLearningRuby(text);
    final List<VocabularyEntry> effectiveVocabularyEntries;
    if (supportMode == LearningSupportMode.off) {
      effectiveVocabularyEntries = vocabularyEntries.isEmpty
          ? vocabularyEntries
          : mergeLearningVocabulary(vocabularyEntries);
    } else if (supportMode == LearningSupportMode.rubyOnly) {
      effectiveVocabularyEntries = const <VocabularyEntry>[];
    } else {
      effectiveVocabularyEntries = mergeLearningVocabulary(vocabularyEntries);
    }
    final lines = supportedText.split('\n');
    final effectiveLanguage = LessonLanguageScope.of(context, language);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAxisAlignment,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          _RubyLine(
            parts: _parseRuby(lines[i], effectiveVocabularyEntries),
            style: effectiveStyle,
            rubyStyle: effectiveRubyStyle,
            alignment: _wrapAlignment,
            language: effectiveLanguage,
          ),
          if (i < lines.length - 1)
            SizedBox(height: effectiveStyle.fontSize ?? 16),
        ],
      ],
    );
  }

  LearningSupportMode get _resolvedLearningSupportMode {
    if (learningSupportMode != null) {
      return learningSupportMode!;
    }
    if (!enableLearningSupport) {
      return LearningSupportMode.off;
    }
    return learningSupportRubyOnly
        ? LearningSupportMode.rubyOnly
        : LearningSupportMode.rubyAndDictionary;
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

  List<_RubyPart> _parseRuby(String line, List<VocabularyEntry> entries) {
    final parts = <_RubyPart>[];
    var index = 0;

    while (index < line.length) {
      final start = line.indexOf('{', index);
      if (start == -1) {
        _addPlainText(parts, line.substring(index), entries);
        break;
      }

      if (start > index) {
        _addPlainText(parts, line.substring(index, start), entries);
      }

      final end = line.indexOf('}', start + 1);
      if (end == -1) {
        _addPlainText(parts, line.substring(start), entries);
        break;
      }

      final content = line.substring(start + 1, end);
      final separator = content.indexOf('|');
      if (separator <= 0 || separator == content.length - 1) {
        _addPlainText(parts, line.substring(start, end + 1), entries);
      } else {
        final base = content.substring(0, separator);
        parts.add(
          _RubyPart(
            base: base,
            ruby: content.substring(separator + 1),
            entry: _entryFor(base, entries),
          ),
        );
      }
      index = end + 1;
    }

    return _fixSchoolMathReadings(_attachSpanningVocabulary(parts, entries));
  }

  List<_RubyPart> _attachSpanningVocabulary(
    List<_RubyPart> parts,
    List<VocabularyEntry> entries,
  ) {
    if (parts.isEmpty || entries.isEmpty) return parts;

    final ranked = entries.toList()
      ..sort((a, b) {
        final aLen = _longestSurfaceLength(a);
        final bLen = _longestSurfaceLength(b);
        return bLen.compareTo(aLen);
      });
    final attached = List<_RubyPart>.from(parts);
    var index = 0;
    while (index < attached.length) {
      var combined = '';
      VocabularyEntry? matched;
      var matchEnd = index;
      for (var end = index; end < attached.length; end++) {
        combined += attached[end].base;
        for (final entry in ranked) {
          if (_surfaceSet(entry).contains(combined)) {
            matched = entry;
            matchEnd = end;
            break;
          }
        }
      }
      if (matched != null) {
        for (var i = index; i <= matchEnd; i++) {
          attached[i] = attached[i].withEntry(matched);
        }
        index = matchEnd + 1;
      } else {
        index++;
      }
    }
    return attached;
  }

  List<_RubyPart> _fixSchoolMathReadings(List<_RubyPart> parts) {
    if (parts.isEmpty) return parts;
    final fixed = List<_RubyPart>.from(parts);
    for (var i = 0; i < fixed.length; i++) {
      final part = fixed[i];
      final next = i + 1 < fixed.length ? fixed[i + 1].base : '';
      final prev = i > 0 ? fixed[i - 1].base : '';
      if (part.base == '何' && _usesNanReading(next)) {
        fixed[i] = part.withRuby('なん');
      }
      if (part.base == '数' &&
          part.ruby != 'ずう' &&
          prev != '人' &&
          !next.startsWith('字') &&
          !next.startsWith('学')) {
        fixed[i] = part.withRuby('かず');
      }
    }
    return fixed;
  }

  bool _usesNanReading(String next) {
    if (next.isEmpty) return false;
    return RegExp(
      r'^(こ|人|台|本|枚|まい|分|時|g|kg|m|cm|km|t|ですか)',
    ).hasMatch(next);
  }

  int _longestSurfaceLength(VocabularyEntry entry) {
    var longest = entry.term.length;
    for (final surface in entry.surfaces) {
      if (surface.length > longest) longest = surface.length;
    }
    return longest;
  }

  Set<String> _surfaceSet(VocabularyEntry entry) {
    return {entry.term, ...entry.surfaces};
  }

  void _addPlainText(
    List<_RubyPart> parts,
    String value,
    List<VocabularyEntry> vocabulary,
  ) {
    var cursor = 0;
    final entries = vocabulary.toList()
      ..sort((a, b) => b.term.length.compareTo(a.term.length));

    while (cursor < value.length) {
      VocabularyEntry? matched;
      String? matchedSurface;
      for (final entry in entries) {
        for (final surface in <String>[entry.term, ...entry.surfaces]) {
          if (surface == 'はかり' && value.startsWith('はかりま', cursor)) {
            continue;
          }
          if (surface == '長い' && value.startsWith('長いす', cursor)) {
            continue;
          }
          if (surface.isEmpty || !value.startsWith(surface, cursor)) continue;
          if (matchedSurface == null || surface.length > matchedSurface.length) {
            matched = entry;
            matchedSurface = surface;
          }
        }
      }

      if (matched != null && matchedSurface != null) {
        parts.add(_RubyPart(base: matchedSurface, entry: matched));
        cursor += matchedSurface.length;
        continue;
      }

      final char = String.fromCharCode(value.substring(cursor).runes.first);
      parts.add(_RubyPart(base: char));
      cursor += char.length;
    }
  }

  VocabularyEntry? _entryFor(String base, List<VocabularyEntry> entries) {
    final normalized = _dictionaryBaseFor(base);
    for (final entry in entries) {
      if (entry.term == normalized || entry.surfaces.contains(normalized)) {
        return entry;
      }
    }
    return null;
  }

  String _dictionaryBaseFor(String base) {
    switch (base) {
      case '分けます':
      case '分けて':
      case '分けた':
      case '分けてみよう':
      case '分けられた':
      case '分けられます':
      case '分けられる':
      case '分け':
        return '分ける';
      case '入ります':
      case '入って':
      case '入った':
        return '入る';
      case '入れます':
      case '入れて':
      case '入れた':
      case '入れられない':
      case '入れられます':
      case '入れられる':
        return '入れる';
      case 'もらいます':
      case 'もらって':
      case 'もらった':
        return 'もらう';
      case '配ります':
      case '配って':
      case '配った':
        return '配る';
      case 'わります':
      case 'わって':
      case 'わった':
        return 'わる';
      case '測ります':
      case '測って':
      case '測った':
        return '測る';
      case 'のこります':
      case 'のこった':
        return 'のこる';
      case '出発して':
        return '出発';
      case '到着します':
        return '到着';
      case '選びます':
      case '選んで':
      case '選び':
      case '選ぼう':
      case '選びましょう':
        return '選ぶ';
      case '考えます':
      case '考えて':
      case '考えた':
      case '考える':
      case '考えよう':
      case '考えましょう':
        return '考える';
      case '比べます':
      case '比べて':
      case '比べた':
      case '比べよう':
      case '比べましょう':
        return '比べる';
      case '動かします':
      case '動かして':
      case '動かした':
      case '動かそう':
        return '動かす';
      case '進めます':
      case '進めて':
      case '進めた':
      case '進めよう':
        return '進める';
      case '戻します':
      case '戻して':
      case '戻した':
        return '戻す';
      case '座ります':
      case '座って':
      case '座らせて':
      case '座れます':
        return '座る';
      case '切ります':
      case '切って':
      case '切った':
        return '切る';
      case '使います':
      case '使って':
      case '使った':
        return '使う';
      case 'かかります':
      case 'かかった':
        return 'かかる';
      case '乗せます':
      case '乗せて':
      case '乗せた':
        return '乗せる';
      case '積みます':
      case '積んで':
      case '積む':
        return '積む';
      case '作ります':
      case '作って':
      case '作った':
        return '作る';
      case '見つけます':
      case '見つけて':
      case '見つけた':
      case '見つけよう':
      case '見つけられます':
      case '見つけられる':
        return '見つける';
      case '置きます':
      case '置いて':
      case '置いた':
        return '置く';
      case '読みます':
      case '読んで':
      case '読んだ':
        return '読む';
      case '見ます':
      case '見て':
      case '見よう':
        return '見る';
      case '始まります':
      case '始まって':
      case '始まった':
        return '始まる';
      case '終わります':
      case '終わって':
      case '終わった':
        return '終わる';
      case '増やします':
      case '増やして':
        return '増やす';
      case '進みます':
      case '進んで':
        return '進む';
      case '合わせます':
      case '合わせて':
      case '合わせた':
        return '合わせる';
      case '届きます':
      case '届いて':
        return '届く';
      case '分かります':
      case '分かった':
        return '分かる';
      case '表します':
      case '表して':
      case '表しています':
        return '表す';
      default:
        return base;
    }
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
        : _buildRubyChild();

    if (part.entry == null) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _showVocabularySheet(context, part.entry!),
      child: child,
    );
  }

  Widget _buildRubyChild() {
    final segments = _splitRubySegments(part.base, part.ruby!);
    final hasKanjiRuby = segments.any(
      (segment) => segment.ruby != null && segment.ruby!.isNotEmpty,
    );
    if (!hasKanjiRuby) {
      return Padding(
        padding: EdgeInsets.only(top: (rubyStyle.fontSize ?? 8) + 2),
        child: Text(part.base, style: _baseStyle),
      );
    }
    if (segments.length == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            segments.first.ruby!,
            style: rubyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(part.base, style: _baseStyle, textAlign: TextAlign.center),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final segment in segments)
          if (segment.ruby == null)
            Padding(
              padding: EdgeInsets.only(top: (rubyStyle.fontSize ?? 8) + 2),
              child: Text(segment.base, style: _baseStyle),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  segment.ruby!,
                  style: rubyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 1),
                Text(
                  segment.base,
                  style: _baseStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
      ],
    );
  }

  List<_RubySegment> _splitRubySegments(String base, String ruby) {
    switch (base) {
      case '同じ数ずつ':
        return const [
          _RubySegment('同', 'おな'),
          _RubySegment('じ'),
          _RubySegment('数', 'かず'),
          _RubySegment('ずつ'),
        ];
      case '同じ数':
        return const [
          _RubySegment('同', 'おな'),
          _RubySegment('じ'),
          _RubySegment('数', 'かず'),
        ];
      case '分けます':
        return const [_RubySegment('分', 'わ'), _RubySegment('けます')];
      case '分ける':
        return const [_RubySegment('分', 'わ'), _RubySegment('ける')];
      case '分けて':
        return const [_RubySegment('分', 'わ'), _RubySegment('けて')];
      case '分けた':
        return const [_RubySegment('分', 'わ'), _RubySegment('けた')];
      case '分けられた':
        return const [_RubySegment('分', 'わ'), _RubySegment('けられた')];
      case '分けられます':
        return const [_RubySegment('分', 'わ'), _RubySegment('けられます')];
      case '分けられる':
        return const [_RubySegment('分', 'わ'), _RubySegment('けられる')];
      case '分け':
        return const [_RubySegment('分', 'わ'), _RubySegment('け')];
      case '入る':
        return const [_RubySegment('入', 'はい'), _RubySegment('る')];
      case '入れる':
        return const [_RubySegment('入', 'い'), _RubySegment('れる')];
      case '配る':
        return const [_RubySegment('配', 'くば'), _RubySegment('る')];
      case '1人分':
        return const [
          _RubySegment('1'),
          _RubySegment('人', 'ひとり'),
          _RubySegment('分', 'ぶん'),
        ];
      case 'わられる数':
        return const [_RubySegment('わられる'), _RubySegment('数', 'かず')];
      case 'わる数':
        return const [_RubySegment('わる'), _RubySegment('数', 'かず')];
      case '全部の数':
        return const [
          _RubySegment('全', 'ぜん'),
          _RubySegment('部', 'ぶ'),
          _RubySegment('の'),
          _RubySegment('数', 'かず'),
        ];
      case '全部':
        return const [_RubySegment('全', 'ぜん'), _RubySegment('部', 'ぶ')];
      case '人数':
        return const [_RubySegment('人', 'にん'), _RubySegment('数', 'ずう')];
      case 'かけ算':
        return const [_RubySegment('かけ'), _RubySegment('算', 'さん')];
      case 'わり算':
        return const [_RubySegment('わり'), _RubySegment('算', 'さん')];
      case '何こずつ':
        return const [
          _RubySegment('何', 'なん'),
          _RubySegment('こ'),
          _RubySegment('ずつ'),
        ];
      case '何こ':
        return const [_RubySegment('何', 'なん'), _RubySegment('こ')];
      case '何人':
        return const [_RubySegment('何', 'なん'), _RubySegment('人', 'にん')];
      case '何台':
        return const [_RubySegment('何', 'なん'), _RubySegment('台', 'だい')];
      case '何本':
        return const [_RubySegment('何', 'なん'), _RubySegment('本', 'ぼん')];
      case '何まい':
      case '何枚':
        return const [_RubySegment('何', 'なん'), _RubySegment('まい')];
      case '何分':
        return const [_RubySegment('何', 'なん'), _RubySegment('分', 'ぷん')];
      case '何時':
        return const [_RubySegment('何', 'なん'), _RubySegment('時', 'じ')];
      case '何時間':
        return const [
          _RubySegment('何', 'なん'),
          _RubySegment('時', 'じ'),
          _RubySegment('間', 'かん'),
        ];
      case '数字':
        return const [_RubySegment('数', 'すう'), _RubySegment('字', 'じ')];
      case '数学':
        return const [_RubySegment('数', 'すう'), _RubySegment('学', 'がく')];
      case '人分':
        return const [_RubySegment('人', 'ひとり'), _RubySegment('分', 'ぶん')];
      case '正しい':
        return const [_RubySegment('正', 'ただ'), _RubySegment('しい')];
      case '書いて':
        return const [_RubySegment('書', 'か'), _RubySegment('いて')];
      case '余ります':
        return const [_RubySegment('余', 'あま'), _RubySegment('ります')];
      case '余り':
        return const [_RubySegment('余', 'あま'), _RubySegment('り')];
      case '作れて':
        return const [_RubySegment('作', 'つく'), _RubySegment('れて')];
      case '時計':
        return const [_RubySegment('時', 'と'), _RubySegment('計', 'けい')];
      case '時刻':
        return const [_RubySegment('時', 'じ'), _RubySegment('刻', 'こく')];
      case '時間':
        return const [_RubySegment('時', 'じ'), _RubySegment('間', 'かん')];
      case '午前':
        return const [_RubySegment('午', 'ご'), _RubySegment('前', 'ぜん')];
      case '午後':
        return const [_RubySegment('午', 'ご'), _RubySegment('後', 'ご')];
      case '出発':
        return const [_RubySegment('出', 'しゅっ'), _RubySegment('発', 'ぱつ')];
      case '出発して':
        return const [
          _RubySegment('出', 'しゅっ'),
          _RubySegment('発', 'ぱつ'),
          _RubySegment('して'),
        ];
      case '到着':
        return const [_RubySegment('到', 'とう'), _RubySegment('着', 'ちゃく')];
      case '到着します':
        return const [
          _RubySegment('到', 'とう'),
          _RubySegment('着', 'ちゃく'),
          _RubySegment('します'),
        ];
      case '長さ':
        return const [_RubySegment('長', 'なが'), _RubySegment('さ')];
      case '測る':
        return const [_RubySegment('測', 'はか'), _RubySegment('る')];
      case '測ります':
        return const [_RubySegment('測', 'はか'), _RubySegment('ります')];
      case '測って':
        return const [_RubySegment('測', 'はか'), _RubySegment('って')];
      case '測った':
        return const [_RubySegment('測', 'はか'), _RubySegment('った')];
      case '巻き尺':
        return const [
          _RubySegment('巻', 'ま'),
          _RubySegment('き'),
          _RubySegment('尺', 'じゃく'),
        ];
      case '道のり':
        return const [_RubySegment('道', 'みち'), _RubySegment('のり')];
      case '距離':
        return const [_RubySegment('距', 'きょ'), _RubySegment('離', 'り')];
      case '重さ':
        return const [_RubySegment('重', 'おも'), _RubySegment('さ')];
      case '重い':
        return const [_RubySegment('重', 'おも'), _RubySegment('い')];
      case '軽い':
        return const [_RubySegment('軽', 'かる'), _RubySegment('い')];
      case '目盛り':
        return const [
          _RubySegment('目', 'め'),
          _RubySegment('盛', 'も'),
          _RubySegment('り'),
        ];
      case '天びん':
        return const [_RubySegment('天', 'てん'), _RubySegment('びん')];
      case '荷物':
        return const [_RubySegment('荷', 'に'), _RubySegment('物', 'もつ')];
      case '自動車':
        return const [
          _RubySegment('自', 'じ'),
          _RubySegment('動', 'どう'),
          _RubySegment('車', 'しゃ'),
        ];
      case '鉛筆':
        return const [_RubySegment('鉛', 'えん'), _RubySegment('筆', 'ぴつ')];
      case '皿':
        return const [_RubySegment('皿', 'さら')];
      case '答え':
        return const [_RubySegment('答', 'こた'), _RubySegment('え')];
      case '式':
        return const [_RubySegment('式', 'しき')];
      case '秒':
        return const [_RubySegment('秒', 'びょう')];
      case 'ビー玉':
        return const [_RubySegment('ビー'), _RubySegment('玉', 'だま')];
      default:
        return [
          for (final span in splitKanjiRuby(base, ruby))
            _RubySegment(span.text, span.ruby),
        ];
    }
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
      isScrollControlled: true,
      builder: (context) {
        final sheetLanguage = language;
        final nativeLabel = sheetLanguage == AppLanguage.japanese
            ? '母国語'
            : sheetLanguage.label;
        final nativeMeaning = nativeMeaningFor(entry, sheetLanguage);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: ListenableBuilder(
              listenable: FavoriteVocabularyStore.instance,
              builder: (context, _) {
                final isFavorite =
                    FavoriteVocabularyStore.instance.isFavorite(entry.term);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            entry.term,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _VocabularyAudioButton(
                          onPressed: () {
                            LearningAudio.play(
                              context,
                              AudioCueFactory.vocabulary(
                                term: entry.term,
                                reading: entry.reading,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _VocabularyFavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: () {
                            unawaited(
                              FavoriteVocabularyStore.instance.toggle(entry),
                            );
                          },
                        ),
                      ],
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
                    _VocabularyBlock(title: '意味', text: entry.simpleJapanese),
                    if (sheetLanguage != AppLanguage.japanese &&
                        nativeMeaning.isNotEmpty &&
                        nativeMeaning != entry.simpleJapanese &&
                        !looksLikeJapaneseGloss(nativeMeaning)) ...[
                      const SizedBox(height: 14),
                      _VocabularyBlock(
                        title: '$nativeLabelで',
                        text: nativeMeaning,
                      ),
                    ],
                    if (entry.exampleSentence.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _VocabularyBlock(
                        title: '例文',
                        text: entry.exampleSentence,
                      ),
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
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _VocabularyAudioButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _VocabularyAudioButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: IconButton(
          tooltip: '音声',
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 20,
          color: const Color(0xFF374151),
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ),
    );
  }
}

class _VocabularyFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _VocabularyFavoriteButton({
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: isFavorite ? const Color(0xFFFFFBEB) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isFavorite
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: IconButton(
          tooltip: isFavorite ? 'お気に入り解除' : 'お気に入り',
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 22,
          color: isFavorite
              ? const Color(0xFFD97706)
              : const Color(0xFF9CA3AF),
          icon: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          ),
        ),
      ),
    );
  }
}

class _RubyPart {
  final String base;
  final String? ruby;
  final VocabularyEntry? entry;

  const _RubyPart({required this.base, this.ruby, this.entry});

  _RubyPart withEntry(VocabularyEntry next) {
    return _RubyPart(base: base, ruby: ruby, entry: next);
  }

  _RubyPart withRuby(String nextRuby) {
    return _RubyPart(base: base, ruby: nextRuby, entry: entry);
  }
}

class _RubySegment {
  final String base;
  final String? ruby;

  const _RubySegment(this.base, [this.ruby]);
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
