import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme/app_fonts.dart';

class QuestionVisual extends StatelessWidget {
  final Question question;
  final bool compact;
  final bool showSolution;

  const QuestionVisual({
    super.key,
    required this.question,
    this.compact = false,
    this.showSolution = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!question.hasVisual) {
      return const SizedBox.shrink();
    }

    if (question.visualType == QuestionVisualType.none) {
      return switch (question.diagramType) {
        'equal_share_boxes' => _DiagramDivisionVisual(
          question: question,
          compact: compact,
          showSolution: showSolution,
          mode: _DiagramDivisionMode.equalShare,
        ),
        'groups_of' => _DiagramDivisionVisual(
          question: question,
          compact: compact,
          showSolution: showSolution,
          mode: _DiagramDivisionMode.groupsOf,
        ),
        'time_line' => _TimeLineVisual(question: question, compact: compact),
        _ => const SizedBox.shrink(),
      };
    }

    switch (question.visualType) {
      case QuestionVisualType.divisionSharing:
      case QuestionVisualType.divisionRemainder:
        return _DivisionVisual(
          question: question,
          compact: compact,
          showSolution: showSolution,
        );
      case QuestionVisualType.numberLine:
        return _NumberLineVisual(
          question: question,
          compact: compact,
          showSolution: showSolution,
        );
      case QuestionVisualType.none:
      case QuestionVisualType.grouping:
      case QuestionVisualType.fraction:
        return const SizedBox.shrink();
    }
  }
}

class _TimeLineVisual extends StatelessWidget {
  final Question question;
  final bool compact;

  const _TimeLineVisual({required this.question, required this.compact});

  @override
  Widget build(BuildContext context) {
    final points = _splitData(question.diagramData['points']);
    final spans = _splitData(question.diagramData['spans']);
    final caption = question.diagramData['caption']?.trim() ?? '';
    if (points.length < 2) return const SizedBox.shrink();
    final useSecondsScale =
        points.any((point) => point.contains('秒')) ||
        spans.any((span) => span.contains('秒'));
    final durations = spans
        .map((span) => _parseDurationValue(span, useSecondsScale))
        .toList();
    if (durations.any((value) => value <= 0)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compact ? 104 : 118,
            child: CustomPaint(
              painter: _QuestionTimeRulerPainter(
                points: points,
                spans: spans,
                durations: durations,
                compact: compact,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionTimeRulerPainter extends CustomPainter {
  final List<String> points;
  final List<String> spans;
  final List<int> durations;
  final bool compact;

  const _QuestionTimeRulerPainter({
    required this.points,
    required this.spans,
    required this.durations,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = durations.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return;

    final left = compact ? 18.0 : 24.0;
    final right = size.width - left;
    final y = compact ? 58.0 : 66.0;
    final width = right - left;
    final basePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), basePaint);

    final boundaries = _cumulativeDurations(durations);
    for (var value = 0; value <= total; value += 10) {
      final x = left + width * value / total;
      final isBoundary =
          value == 0 || value == total || boundaries.contains(value);
      canvas.drawLine(
        Offset(x, y - (isBoundary ? 14 : 8)),
        Offset(x, y + (isBoundary ? 14 : 8)),
        Paint()
          ..color = isBoundary
              ? const Color(0xFF475569)
              : const Color(0xFF94A3B8)
          ..strokeWidth = isBoundary ? 2.2 : 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    var elapsed = 0;
    for (var i = 0; i < durations.length; i++) {
      final startX = left + width * elapsed / total;
      elapsed += durations[i];
      final endX = left + width * elapsed / total;
      final barY = compact ? 26.0 : 28.0;
      final barPaint = Paint()
        ..color = const Color(0xFF2563EB)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(startX + 4, barY),
        Offset(endX - 4, barY),
        barPaint,
      );
      canvas.drawLine(Offset(startX, barY), Offset(startX, barY + 9), barPaint);
      canvas.drawLine(Offset(endX, barY), Offset(endX, barY + 9), barPaint);
      _paintText(
        canvas,
        spans[i],
        Offset((startX + endX) / 2, barY - 12),
        compact ? 12 : 13,
        const Color(0xFF2563EB),
      );
    }

    final positions = <double>[0];
    var sum = 0;
    for (final duration in durations) {
      sum += duration;
      positions.add(sum / total);
    }
    for (var i = 0; i < points.length && i < positions.length; i++) {
      _paintText(
        canvas,
        points[i],
        Offset(left + width * positions[i], y + 30),
        compact ? 11 : 12,
        const Color(0xFF334155),
      );
    }
  }

  List<int> _cumulativeDurations(List<int> values) {
    var sum = 0;
    final result = <int>[];
    for (final value in values) {
      sum += value;
      if (sum > 0) result.add(sum);
    }
    return result;
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _QuestionTimeRulerPainter oldDelegate) {
    return points != oldDelegate.points ||
        spans != oldDelegate.spans ||
        durations != oldDelegate.durations ||
        compact != oldDelegate.compact;
  }
}

List<String> _splitData(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  return value.split('|').where((part) => part.trim().isNotEmpty).toList();
}

int _parseDurationValue(String value, bool useSecondsScale) {
  final normalized = value.replaceAll(' ', '');
  final minutesMatch = RegExp(r'(\d+)分').firstMatch(normalized);
  final secondsMatch = RegExp(r'(\d+)秒').firstMatch(normalized);
  final minutes = minutesMatch == null
      ? 0
      : int.tryParse(minutesMatch.group(1)!) ?? 0;
  final seconds = secondsMatch == null
      ? 0
      : int.tryParse(secondsMatch.group(1)!) ?? 0;
  if (minutesMatch != null) {
    return useSecondsScale ? minutes * 60 + seconds : minutes;
  }
  if (secondsMatch != null) return seconds;
  return int.tryParse(normalized.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

enum _DiagramDivisionMode { equalShare, groupsOf }

class _DiagramDivisionVisual extends StatelessWidget {
  final Question question;
  final bool compact;
  final bool showSolution;
  final _DiagramDivisionMode mode;

  const _DiagramDivisionVisual({
    required this.question,
    required this.compact,
    required this.showSolution,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final total = _parseInt(question.diagramData['total']) ?? 0;
    final groups = _parseInt(question.diagramData['groups']) ?? 0;
    final each = _parseInt(question.diagramData['each']) ?? 0;
    if (total <= 0 || groups <= 0 || each <= 0) {
      return const SizedBox.shrink();
    }

    final itemEmoji = _diagramItemEmoji(question);
    final groupLabel = mode == _DiagramDivisionMode.equalShare ? '人目' : '組目';
    final cardWidth = compact ? 132.0 : 160.0;
    const cardGap = 10.0;
    final totalWidth = groups * cardWidth + (groups - 1) * cardGap;
    final hideAnswerGroups =
        mode == _DiagramDivisionMode.groupsOf && !showSolution;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canUseFixedWidth = totalWidth <= constraints.maxWidth;

          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: canUseFixedWidth ? totalWidth : constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalItemsRow(
                    count: total,
                    itemEmoji: itemEmoji,
                    itemUnit: question.itemUnit,
                    compact: compact,
                  ),
                  if (!hideAnswerGroups) ...[
                    SizedBox(height: compact ? 12 : 16),
                    Wrap(
                      spacing: cardGap,
                      runSpacing: 10,
                      children: [
                        for (var index = 0; index < groups; index++)
                          SizedBox(
                            width: canUseFixedWidth ? cardWidth : null,
                            child: _GroupCard(
                              label: '${index + 1}$groupLabel',
                              count: each,
                              itemEmoji: itemEmoji,
                              compact: compact,
                              showSolution: showSolution,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DivisionVisual extends StatelessWidget {
  final Question question;
  final bool compact;
  final bool showSolution;

  const _DivisionVisual({
    required this.question,
    required this.compact,
    required this.showSolution,
  });

  @override
  Widget build(BuildContext context) {
    final groupCount = question.groupCount ?? 0;
    final perGroupCount = question.perGroupCount ?? 0;
    final remainderCount = question.remainderCount ?? 0;
    final totalCount =
        question.totalCount ?? groupCount * perGroupCount + remainderCount;
    final itemEmoji = question.itemEmoji;
    final itemUnit = question.itemUnit;
    final shouldShowGroups =
        showSolution ||
        question.visualType != QuestionVisualType.divisionRemainder;
    final shouldShowRemainderBox =
        question.visualType == QuestionVisualType.divisionRemainder &&
        showSolution &&
        remainderCount > 0;

    if (groupCount <= 0 || perGroupCount <= 0 || totalCount <= 0) {
      return const SizedBox.shrink();
    }

    final groupCardWidth = compact ? 132.0 : 160.0;
    const groupCardGap = 12.0;
    final remainderSlots = shouldShowRemainderBox ? 1 : 0;
    final visualCardCount = shouldShowGroups ? groupCount + remainderSlots : 0;
    final visualWidth = visualCardCount <= 0
        ? 0.0
        : visualCardCount * groupCardWidth +
              (visualCardCount - 1) * groupCardGap;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canUseFixedWidth =
              visualCardCount > 0 && visualWidth <= constraints.maxWidth;

          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: canUseFixedWidth ? visualWidth : constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotalItemsRow(
                    count: totalCount,
                    itemEmoji: itemEmoji,
                    itemUnit: itemUnit,
                    compact: compact,
                  ),
                  if (shouldShowGroups) ...[
                    SizedBox(height: compact ? 14 : 18),
                    Wrap(
                      spacing: groupCardGap,
                      runSpacing: 12,
                      children: [
                        for (var index = 0; index < groupCount; index++)
                          SizedBox(
                            width: canUseFixedWidth ? groupCardWidth : null,
                            child: _GroupCard(
                              label: '${index + 1}人目',
                              count: perGroupCount,
                              itemEmoji: itemEmoji,
                              compact: compact,
                              showSolution: showSolution,
                            ),
                          ),
                        if (shouldShowRemainderBox)
                          SizedBox(
                            width: canUseFixedWidth ? groupCardWidth : null,
                            child: _RemainderCard(
                              count: remainderCount,
                              itemEmoji: itemEmoji,
                              compact: compact,
                              showSolution: showSolution,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberLineVisual extends StatelessWidget {
  final Question question;
  final bool compact;
  final bool showSolution;

  const _NumberLineVisual({
    required this.question,
    required this.compact,
    required this.showSolution,
  });

  @override
  Widget build(BuildContext context) {
    final pointCount =
        _parseInt(question.diagramData['points']) ?? question.totalCount ?? 0;
    final segmentCount =
        _parseInt(question.diagramData['segments']) ??
        question.groupCount ??
        (pointCount > 0 ? pointCount - 1 : 0);
    final pointEmoji = question.diagramData['pointEmoji'] ?? question.itemEmoji;
    final totalLabel = question.diagramData['totalLabel'] ?? '';
    final knownSegmentLabel = question.diagramData['segmentLabel'] ?? '';
    final unknownLabel = question.diagramData['unknownLabel'] ?? '？';
    final segmentLabel = showSolution && knownSegmentLabel.isNotEmpty
        ? knownSegmentLabel
        : unknownLabel;

    if (pointCount <= 1 || segmentCount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSolution && question.visualDescription.isNotEmpty) ...[
            Text(
              question.visualDescription,
              style: TextStyle(
                color: const Color(0xFF4B5563),
                fontSize: compact ? 14 : 16,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var index = 0; index < pointCount; index++) ...[
                      _PointMarker(
                        emoji: pointEmoji,
                        label: '${index + 1}本目',
                        compact: compact,
                      ),
                      if (index < pointCount - 1)
                        _IntervalSegment(label: segmentLabel, compact: compact),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _VisualBadge(
                label:
                    '${question.itemLabel.isEmpty ? '点' : question.itemLabel}は$pointCount${question.itemUnit}',
                color: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1D4ED8),
              ),
              _VisualBadge(
                label: '間は$segmentCountつ',
                color: const Color(0xFFFFF7ED),
                textColor: const Color(0xFFC2410C),
              ),
              if (totalLabel.isNotEmpty)
                _VisualBadge(
                  label: totalLabel,
                  color: const Color(0xFFF0FDF4),
                  textColor: const Color(0xFF15803D),
                ),
              _VisualBadge(
                label: showSolution ? '1つ分は$segmentLabel' : '1つ分は$unknownLabel',
                color: const Color(0xFFF0FDF4),
                textColor: const Color(0xFF15803D),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointMarker extends StatelessWidget {
  final String emoji;
  final String label;
  final bool compact;

  const _PointMarker({
    required this.emoji,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 42 : 52,
          height: compact ? 42 : 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF93C5FD), width: 2),
          ),
          child: Text(emoji, style: TextStyle(fontSize: compact ? 22 : 28)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF4B5563),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _IntervalSegment extends StatelessWidget {
  final String label;
  final bool compact;

  const _IntervalSegment({required this.label, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 20 : 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 54 : 72,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFC2410C),
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _VisualBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

int? _parseInt(String? value) {
  if (value == null) return null;
  return int.tryParse(value);
}

String _diagramItemEmoji(Question question) {
  if (question.itemEmoji != '●') return question.itemEmoji;
  final text = [
    question.promptSchoolJa,
    question.promptEasyJa,
    question.visualHint,
    question.pictureDescription,
  ].join(' ');
  if (text.contains('りんご')) return '🍎';
  if (text.contains('あめ')) return '🍬';
  if (text.contains('クッキー')) return '🍪';
  if (text.contains('シール')) return '◯';
  if (text.contains('カード')) return '▣';
  if (text.contains('えんぴつ')) return '✎';
  if (text.contains('みかん')) return '🍊';
  return '●';
}

class _TotalItemsRow extends StatelessWidget {
  final int count;
  final String itemEmoji;
  final String itemUnit;
  final bool compact;

  const _TotalItemsRow({
    required this.count,
    required this.itemEmoji,
    required this.itemUnit,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ぜんぶで $count$itemUnit',
            style: TextStyle(
              color: const Color(0xFF374151),
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: compact ? 5 : 7,
            runSpacing: compact ? 5 : 7,
            children: [
              for (var i = 0; i < count; i++)
                _ItemChip(itemEmoji: itemEmoji, compact: compact),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String label;
  final int count;
  final String itemEmoji;
  final bool compact;
  final bool showSolution;

  const _GroupCard({
    required this.label,
    required this.count,
    required this.itemEmoji,
    required this.compact,
    required this.showSolution,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 132 : 160,
        maxWidth: compact ? 170 : 210,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF166534),
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (showSolution)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < count; i++)
                    _ItemChip(itemEmoji: itemEmoji, compact: compact),
                ],
              )
            else
              const _QuestionMarkBox(),
          ],
        ),
      ),
    );
  }
}

class _RemainderCard extends StatelessWidget {
  final int count;
  final String itemEmoji;
  final bool compact;
  final bool showSolution;

  const _RemainderCard({
    required this.count,
    required this.itemEmoji,
    required this.compact,
    required this.showSolution,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 132 : 160,
        maxWidth: compact ? 170 : 210,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFBBF24), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あまり',
              style: TextStyle(
                color: const Color(0xFF92400E),
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (showSolution)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < count; i++)
                    _ItemChip(itemEmoji: itemEmoji, compact: compact),
                ],
              )
            else
              const _QuestionMarkBox(),
          ],
        ),
      ),
    );
  }
}

class _QuestionMarkBox extends StatelessWidget {
  const _QuestionMarkBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
      ),
      child: const Text(
        '?',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String itemEmoji;
  final bool compact;

  const _ItemChip({required this.itemEmoji, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 30 : 36,
      height: compact ? 30 : 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(itemEmoji, style: TextStyle(fontSize: compact ? 17 : 20)),
    );
  }
}
