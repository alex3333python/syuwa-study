import 'dart:math' as math;

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
        'length_bar' => _LengthBarVisual(question: question, compact: compact),
        'eraser_ruler' => _EraserRulerVisual(
          question: question,
          compact: compact,
        ),
        'distance_map' => _DistanceMapVisual(
          question: question,
          compact: compact,
        ),
        'weight_scale' => _WeightScaleVisual(
          question: question,
          compact: compact,
        ),
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

class _WeightScaleVisual extends StatelessWidget {
  final Question question;
  final bool compact;

  const _WeightScaleVisual({required this.question, required this.compact});

  @override
  Widget build(BuildContext context) {
    final grams = int.tryParse(question.diagramData['grams'] ?? '') ?? 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: SizedBox(
          width: compact ? 240 : 320,
          height: compact ? 190 : 230,
          child: CustomPaint(
            painter: _QuestionScalePainter(grams: grams),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _QuestionScalePainter extends CustomPainter {
  final int grams;

  const _QuestionScalePainter({required this.grams});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(14, 8, size.width - 28, size.height - 16),
      const Radius.circular(28),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEFF6FF)],
        ).createShader(bodyRect.outerRect),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    final dialCenter = Offset(size.width / 2, size.height * 0.42);
    final dialRadius = math.min(size.width, size.height) * 0.33;
    canvas.drawCircle(dialCenter, dialRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      dialCenter,
      dialRadius,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    final arcRect = Rect.fromCircle(center: dialCenter, radius: dialRadius - 18);
    canvas.drawArc(
      arcRect,
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i <= 20; i++) {
      final angle = math.pi * 1.12 + math.pi * 0.76 * i / 20;
      final isMajor = i % 10 == 0;
      final isMedium = i % 5 == 0;
      final outer = dialCenter +
          Offset(math.cos(angle), math.sin(angle)) * (dialRadius - 12);
      final inner = dialCenter +
          Offset(math.cos(angle), math.sin(angle)) *
              (dialRadius - (isMajor ? 32 : isMedium ? 26 : 20));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = const Color(0xFF64748B)
          ..strokeWidth = isMajor ? 3 : 1.6
          ..strokeCap = StrokeCap.round,
      );
      if (isMajor) {
        final label = i == 0 ? '0' : i == 10 ? '500' : '1kg';
        _paintText(
          canvas,
          label,
          dialCenter +
              Offset(math.cos(angle), math.sin(angle)) * (dialRadius - 46),
          13,
          const Color(0xFF334155),
        );
      }
    }

    final clamped = grams.clamp(0, 1000);
    final angle = math.pi * 1.12 + math.pi * 0.76 * clamped / 1000;
    final needleEnd = dialCenter +
        Offset(math.cos(angle), math.sin(angle)) * (dialRadius - 34);
    canvas.drawLine(
      dialCenter,
      needleEnd,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(dialCenter, 7, Paint()..color = const Color(0xFFEF4444));

    final trayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.82),
        width: size.width * 0.58,
        height: 24,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(trayRect, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(
      trayRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _QuestionScalePainter oldDelegate) {
    return grams != oldDelegate.grams;
  }
}

class _EraserRulerVisual extends StatelessWidget {
  final Question question;
  final bool compact;

  const _EraserRulerVisual({required this.question, required this.compact});

  @override
  Widget build(BuildContext context) {
    final lengthCm =
        double.tryParse(question.diagramData['lengthCm'] ?? '') ?? 4;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SizedBox(
        height: compact ? 150 : 190,
        child: CustomPaint(
          painter: _EraserRulerPainter(lengthCm: lengthCm),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _EraserRulerPainter extends CustomPainter {
  final double lengthCm;

  const _EraserRulerPainter({required this.lengthCm});

  @override
  void paint(Canvas canvas, Size size) {
    final rulerWidth = math.min(size.width - 80, 520.0);
    final rulerLeft = (size.width - rulerWidth) / 2;
    final rulerRight = rulerLeft + rulerWidth;
    final rulerTop = size.height - 70;
    final rulerHeight = 44.0;
    final cmWidth = rulerWidth / 6;
    final eraserLeft = rulerLeft;
    final eraserRight = rulerLeft + cmWidth * lengthCm.clamp(1, 6);
    final eraserTop = rulerTop - 62;
    final eraserHeight = 42.0;

    final guidePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(eraserLeft, eraserTop + eraserHeight),
      Offset(eraserLeft, rulerTop + rulerHeight + 12),
      guidePaint,
    );
    canvas.drawLine(
      Offset(eraserRight, eraserTop + eraserHeight),
      Offset(eraserRight, rulerTop + rulerHeight + 12),
      guidePaint,
    );

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        eraserLeft + 2,
        eraserTop + 5,
        eraserRight + 2,
        eraserTop + eraserHeight + 5,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      shadowRect,
      Paint()..color = const Color(0xFF94A3B8).withOpacity(.18),
    );

    final eraserRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        eraserLeft,
        eraserTop,
        eraserRight,
        eraserTop + eraserHeight,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      eraserRect,
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          eraserLeft + 8,
          eraserTop + 6,
          eraserRight - 8,
          eraserTop + 16,
        ),
        const Radius.circular(999),
      ),
      Paint()..color = Colors.white.withOpacity(.8),
    );
    canvas.drawRRect(
      eraserRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(
          eraserLeft,
          eraserTop,
          eraserLeft + 30,
          eraserTop + eraserHeight,
        ),
        topLeft: const Radius.circular(10),
        bottomLeft: const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFFCA5A5),
    );
    final sleeveLeft = eraserLeft + (eraserRight - eraserLeft) * 0.46;
    final sleeveRight = eraserLeft + (eraserRight - eraserLeft) * 0.76;
    final sleeveRect = Rect.fromLTRB(
      sleeveLeft,
      eraserTop,
      sleeveRight,
      eraserTop + eraserHeight,
    );
    canvas.drawRect(sleeveRect, Paint()..color = const Color(0xFF60A5FA));
    canvas.drawRect(
      Rect.fromLTRB(sleeveLeft, eraserTop, sleeveLeft + 5, eraserTop + eraserHeight),
      Paint()..color = const Color(0xFF2563EB).withOpacity(.45),
    );
    canvas.drawRect(
      Rect.fromLTRB(sleeveRight - 5, eraserTop, sleeveRight, eraserTop + eraserHeight),
      Paint()..color = const Color(0xFF2563EB).withOpacity(.45),
    );
    canvas.drawLine(
      Offset(sleeveLeft + 10, eraserTop + eraserHeight * .62),
      Offset(sleeveRight - 10, eraserTop + eraserHeight * .62),
      Paint()
        ..color = Colors.white.withOpacity(.7)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final rulerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rulerLeft, rulerTop, rulerWidth, rulerHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rulerRect,
      Paint()..color = const Color(0xFFFEF3C7),
    );
    canvas.drawRRect(
      rulerRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (var cm = 0; cm <= 6; cm++) {
      final x = rulerLeft + cmWidth * cm;
      canvas.drawLine(
        Offset(x, rulerTop),
        Offset(x, rulerTop + 24),
        Paint()
          ..color = const Color(0xFF111827)
          ..strokeWidth = cm == 0 || cm == 5 ? 2.8 : 2,
      );
      if (cm == 5) {
        _paintText(
          canvas,
          '5',
          Offset(x, rulerTop + 34),
          12,
          const Color(0xFF334155),
          FontWeight.w800,
        );
      }
      if (cm < 6) {
        for (var sub = 1; sub < 10; sub++) {
          final sx = x + cmWidth * sub / 10;
          final isHalf = sub == 5;
          canvas.drawLine(
            Offset(sx, rulerTop),
            Offset(sx, rulerTop + (isHalf ? 17 : 10)),
            Paint()
              ..color = const Color(0xFF64748B)
              ..strokeWidth = isHalf ? 1.4 : 0.8,
          );
        }
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: size,
          fontWeight: weight,
          color: color,
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
  bool shouldRepaint(covariant _EraserRulerPainter oldDelegate) {
    return lengthCm != oldDelegate.lengthCm;
  }
}

class _LengthBarVisual extends StatelessWidget {
  final Question question;
  final bool compact;

  const _LengthBarVisual({required this.question, required this.compact});

  @override
  Widget build(BuildContext context) {
    final label = question.diagramData['label']?.trim() ?? '';
    final value = question.diagramData['value']?.trim() ?? '';
    final ticks = _splitData(question.diagramData['ticks']);
    if (ticks.length < 2) return const SizedBox.shrink();

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
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: compact ? 82 : 96,
            child: CustomPaint(
              painter: _QuestionLengthBarPainter(ticks: ticks, value: value),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionLengthBarPainter extends CustomPainter {
  final List<String> ticks;
  final String value;

  const _QuestionLengthBarPainter({required this.ticks, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final left = 20.0;
    final right = size.width - 20;
    final y = 34.0;
    final width = right - left;
    final basePaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), basePaint);

    for (var i = 0; i < ticks.length; i++) {
      final x = left + width * i / (ticks.length - 1);
      canvas.drawLine(
        Offset(x, y - 17),
        Offset(x, y + 17),
        Paint()
          ..color = const Color(0xFF475569)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      _paintText(
        canvas,
        ticks[i],
        Offset(x, y + 34),
        11,
        const Color(0xFF334155),
      );
    }
    if (value.isNotEmpty) {
      _paintText(
        canvas,
        value,
        Offset(right, y - 28),
        16,
        const Color(0xFF2563EB),
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
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
  bool shouldRepaint(covariant _QuestionLengthBarPainter oldDelegate) {
    return ticks != oldDelegate.ticks || value != oldDelegate.value;
  }
}

class _DistanceMapVisual extends StatelessWidget {
  final Question question;
  final bool compact;

  const _DistanceMapVisual({required this.question, required this.compact});

  @override
  Widget build(BuildContext context) {
    final places = _splitData(question.diagramData['places']);
    final segments = _splitData(question.diagramData['segments']);
    final caption = question.diagramData['caption']?.trim() ?? '';
    if (places.length < 2 || segments.length != places.length - 1) {
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
        children: [
          SizedBox(
            height: compact ? 132 : 156,
            child: CustomPaint(
              painter: _QuestionDistanceMapPainter(
                places: places,
                segments: segments,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionDistanceMapPainter extends CustomPainter {
  final List<String> places;
  final List<String> segments;

  const _QuestionDistanceMapPainter({
    required this.places,
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (var i = 0; i < places.length; i++) {
      final x = size.width * (0.08 + 0.84 * i / (places.length - 1));
      final y = size.height * (i.isEven ? .58 : .36);
      points.add(Offset(x, y));
    }
    final road = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], road);
      _paintText(
        canvas,
        segments[i],
        (points[i] + points[i + 1]) / 2 + const Offset(0, -16),
        12,
        const Color(0xFF334155),
      );
    }
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 11, Paint()..color = Colors.white);
      canvas.drawCircle(
        points[i],
        11,
        Paint()
          ..color = const Color(0xFF2563EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      _paintText(
        canvas,
        places[i],
        points[i] + const Offset(0, 28),
        12,
        const Color(0xFF111827),
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.interface,
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
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
  bool shouldRepaint(covariant _QuestionDistanceMapPainter oldDelegate) {
    return places != oldDelegate.places || segments != oldDelegate.segments;
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
            alignment: Alignment.center,
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
                      alignment: WrapAlignment.center,
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
    final itemEmoji = question.itemEmoji == '●'
        ? _diagramItemEmoji(question)
        : question.itemEmoji;
    final itemUnit = question.itemUnit;

    if (itemEmoji == 'ribbon' || itemEmoji == 'rope') {
      return _RibbonDivisionVisual(
        totalLength: totalCount,
        groupCount: groupCount,
        pieceLength: perGroupCount,
        remainderLength: remainderCount,
        compact: compact,
        showSolution: showSolution,
        isCord: itemEmoji == 'rope',
      );
    }

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
            alignment: Alignment.center,
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
                      alignment: WrapAlignment.center,
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
                              firstItemIndex: index * perGroupCount,
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
                              firstItemIndex: groupCount * perGroupCount,
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

/// A ribbon is one continuous object before cutting.  After the answer is
/// shown, its cut pieces replace the generic equal-sharing item diagram.
class _RibbonDivisionVisual extends StatelessWidget {
  final int totalLength;
  final int groupCount;
  final int pieceLength;
  final int remainderLength;
  final bool compact;
  final bool showSolution;
  final bool isCord;

  const _RibbonDivisionVisual({
    required this.totalLength,
    required this.groupCount,
    required this.pieceLength,
    required this.remainderLength,
    required this.compact,
    required this.showSolution,
    this.isCord = false,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = [
      for (var index = 0; index < groupCount; index++) pieceLength,
      if (remainderLength > 0) remainderLength,
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: showSolution
              ? _CutRibbonPieces(
                  pieces: pieces,
                  compact: compact,
                  isCord: isCord,
                )
              : _WholeRibbon(
                  length: totalLength,
                  compact: compact,
                  isCord: isCord,
                ),
        ),
      ),
    );
  }
}

class _WholeRibbon extends StatelessWidget {
  final int length;
  final bool compact;
  final bool isCord;

  const _WholeRibbon({
    required this.length,
    required this.compact,
    this.isCord = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$length cmの${isCord ? 'ひも' : 'リボン'}',
          style: TextStyle(
            color: const Color(0xFF374151),
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        SizedBox(
          width: double.infinity,
          height: compact ? 34 : 44,
          child: CustomPaint(
            painter: isCord
                ? const _CordPiecePainter()
                : const _RibbonPiecePainter(),
          ),
        ),
      ],
    );
  }
}

class _CutRibbonPieces extends StatelessWidget {
  final List<int> pieces;
  final bool compact;
  final bool isCord;

  const _CutRibbonPieces({
    required this.pieces,
    required this.compact,
    this.isCord = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalLength = pieces.fold<int>(0, (sum, length) => sum + length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '切った${isCord ? 'ひも' : 'リボン'}',
          style: TextStyle(
            color: const Color(0xFF374151),
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < pieces.length; index++) ...[
              Expanded(
                flex: pieces[index],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: compact ? 30 : 40,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: isCord
                            ? const _CordPiecePainter()
                            : const _RibbonPiecePainter(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${pieces[index]}cm',
                      style: TextStyle(
                        color: index == pieces.length - 1 &&
                                pieces[index] != totalLength
                            ? const Color(0xFFC2410C)
                            : const Color(0xFF9D174D),
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < pieces.length - 1) SizedBox(width: compact ? 8 : 12),
            ],
          ],
        ),
      ],
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
    final isIntervalLine = question.diagramType == 'interval_line';

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
          if (!isIntervalLine &&
              showSolution &&
              question.visualDescription.isNotEmpty) ...[
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
                        plain: isIntervalLine,
                      ),
                      if (index < pointCount - 1)
                        _IntervalSegment(label: segmentLabel, compact: compact),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isIntervalLine) ...[
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
                  label:
                      showSolution ? '1つ分は$segmentLabel' : '1つ分は$unknownLabel',
                  color: const Color(0xFFF0FDF4),
                  textColor: const Color(0xFF15803D),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PointMarker extends StatelessWidget {
  final String emoji;
  final String label;
  final bool compact;
  final bool plain;

  const _PointMarker({
    required this.emoji,
    required this.label,
    required this.compact,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (plain)
          SizedBox(
            width: compact ? 42 : 52,
            height: compact ? 42 : 52,
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: compact ? 24 : 30)),
            ),
          )
        else
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
  if (text.contains('いちご')) return 'strawberry';
  if (text.contains('りんご')) return 'apple';
  if (text.contains('あめ')) return 'candy';
  if (text.contains('クッキー')) return 'cookie';
  if (text.contains('シール')) return 'sticker';
  if (text.contains('カード')) return 'card';
  if (text.contains('ビー玉')) return 'marble';
  if (text.contains('えんぴつ')) return 'pencil';
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
                _ItemChip(
                  itemEmoji: itemEmoji,
                  compact: compact,
                  variant: i,
                ),
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
  final int firstItemIndex;

  const _GroupCard({
    required this.label,
    required this.count,
    required this.itemEmoji,
    required this.compact,
    required this.showSolution,
    this.firstItemIndex = 0,
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
                    _ItemChip(
                      itemEmoji: itemEmoji,
                      compact: compact,
                      variant: firstItemIndex + i,
                    ),
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
  final int firstItemIndex;

  const _RemainderCard({
    required this.count,
    required this.itemEmoji,
    required this.compact,
    required this.showSolution,
    this.firstItemIndex = 0,
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
                    _ItemChip(
                      itemEmoji: itemEmoji,
                      compact: compact,
                      variant: firstItemIndex + i,
                    ),
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
  final int variant;

  const _ItemChip({
    required this.itemEmoji,
    required this.compact,
    this.variant = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (itemEmoji == '👤' || itemEmoji == 'person') {
      return SizedBox(
        width: compact ? 25 : 30,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: _MiniPersonPainter(variant: variant)),
      );
    }
    if (itemEmoji == 'sticker') {
      return SizedBox(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: const _StickerPainter()),
      );
    }
    if (itemEmoji == 'card') {
      return SizedBox(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: const _MiniCardPainter()),
      );
    }
    if (itemEmoji == 'marble') {
      return SizedBox(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: const _MarblePainter()),
      );
    }
    if (itemEmoji == 'candy' || itemEmoji == '🍬') {
      return SizedBox(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: const _CandyPainter()),
      );
    }
    if (itemEmoji == 'apple' || itemEmoji == '🍎') {
      return SizedBox(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: const _ApplePainter()),
      );
    }
    if (itemEmoji == 'strawberry' || itemEmoji.contains('🍓')) {
      return SizedBox(
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
        child: CustomPaint(painter: const _StrawberryPainter()),
      );
    }
    if (itemEmoji == 'cookie' || itemEmoji == '🍪') {
      return SizedBox(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        child: CustomPaint(painter: const _CookiePainter()),
      );
    }
    if (itemEmoji == 'ribbon') {
      return SizedBox(
        width: compact ? 26 : 32,
        height: compact ? 20 : 24,
        child: CustomPaint(painter: const _RibbonPiecePainter()),
      );
    }
    if (itemEmoji == 'pencil' || itemEmoji == '✎') {
      return SizedBox(
        width: compact ? 34 : 40,
        height: compact ? 22 : 26,
        child: CustomPaint(painter: const _PencilPainter()),
      );
    }

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

/// A compact person illustration for quantity diagrams.  It deliberately has
/// no circular backing so a row reads as people rather than repeated symbols.
class _MiniPersonPainter extends CustomPainter {
  final int variant;

  const _MiniPersonPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    const skinTones = [
      Color(0xFFF7D0B5),
      Color(0xFFE9B28E),
      Color(0xFFC9845E),
      Color(0xFF8F563C),
      Color(0xFF6D422F),
      Color(0xFFF2C59C),
    ];
    const shirtColors = [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFDB2777),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFDC2626),
      Color(0xFF65A30D),
    ];
    const hairColors = [
      Color(0xFF3B2417),
      Color(0xFF14171F),
      Color(0xFF7C4526),
      Color(0xFF241B1A),
      Color(0xFFB45309),
      Color(0xFF1F2937),
    ];

    final style = variant % 8;
    final skin = skinTones[variant % skinTones.length];
    final shirt = shirtColors[variant % shirtColors.length];
    final hair = hairColors[variant % hairColors.length];
    final cx = size.width / 2;
    final headTop = size.height * 0.12;
    final headHeight = size.height * 0.41;
    final headRect = Rect.fromCenter(
      center: Offset(cx, headTop + headHeight / 2),
      width: size.width * 0.50,
      height: headHeight,
    );

    final bodyPaint = Paint()..color = shirt;
    final skinPaint = Paint()..color = skin;
    final hairPaint = Paint()..color = hair;
    final featurePaint = Paint()
      ..color = const Color(0xFF374151)
      ..strokeWidth = math.max(0.8, size.width * 0.045)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Hair behind the face for longer styles. Style 4 uses an asymmetric
    // outline instead of an oval so the hairstyle does not read as a blob.
    if (style == 4) {
      final backHairPath = Path()
        ..moveTo(cx - size.width * 0.29, headTop + size.height * 0.18)
        ..quadraticBezierTo(
          cx - size.width * 0.35,
          headTop + size.height * 0.42,
          cx - size.width * 0.25,
          size.height * 0.66,
        )
        ..quadraticBezierTo(
          cx - size.width * 0.13,
          size.height * 0.71,
          cx,
          size.height * 0.67,
        )
        ..quadraticBezierTo(
          cx + size.width * 0.17,
          size.height * 0.72,
          cx + size.width * 0.29,
          size.height * 0.64,
        )
        ..quadraticBezierTo(
          cx + size.width * 0.35,
          headTop + size.height * 0.34,
          cx + size.width * 0.25,
          headTop + size.height * 0.12,
        )
        ..quadraticBezierTo(
          cx,
          headTop - size.height * 0.05,
          cx - size.width * 0.29,
          headTop + size.height * 0.18,
        )
        ..close();
      canvas.drawPath(backHairPath, hairPaint);
    } else if (style == 5 || style == 7) {
      final backHair = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - size.width * 0.31,
          headTop + size.height * 0.06,
          size.width * 0.62,
          size.height * 0.48,
        ),
        Radius.circular(size.width * 0.26),
      );
      canvas.drawRRect(backHair, hairPaint);
    }

    // A shirt with connected shoulders keeps the character readable at this size.
    final bodyPath = Path()
      ..moveTo(cx - size.width * 0.38, size.height * 0.94)
      ..quadraticBezierTo(
        cx - size.width * 0.31,
        size.height * 0.62,
        cx - size.width * 0.16,
        size.height * 0.60,
      )
      ..lineTo(cx + size.width * 0.16, size.height * 0.60)
      ..quadraticBezierTo(
        cx + size.width * 0.31,
        size.height * 0.62,
        cx + size.width * 0.38,
        size.height * 0.94,
      )
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    canvas.drawOval(headRect, skinPaint);

    // Different fringe and hair silhouettes make the individual people visible.
    final hairPath = Path();
    switch (style) {
      case 0:
        hairPath
          ..moveTo(headRect.left, headRect.top + headRect.height * 0.42)
          ..quadraticBezierTo(cx, headRect.top - size.height * 0.06,
              headRect.right, headRect.top + headRect.height * 0.42)
          ..lineTo(headRect.right - size.width * 0.04, headRect.top + headRect.height * 0.20)
          ..quadraticBezierTo(cx, headRect.top + size.height * 0.02,
              headRect.left + size.width * 0.04, headRect.top + headRect.height * 0.20)
          ..close();
        break;
      case 1:
        hairPath
          ..moveTo(headRect.left - size.width * 0.08,
              headRect.top + headRect.height * 0.47)
          ..cubicTo(
            headRect.left - size.width * 0.07,
            headRect.top + headRect.height * 0.12,
            cx - size.width * 0.20,
            headRect.top - size.height * 0.07,
            cx,
            headRect.top - size.height * 0.08,
          )
          ..cubicTo(
            cx + size.width * 0.20,
            headRect.top - size.height * 0.07,
            headRect.right + size.width * 0.07,
            headRect.top + headRect.height * 0.12,
            headRect.right + size.width * 0.08,
            headRect.top + headRect.height * 0.47,
          )
          ..lineTo(headRect.right - size.width * 0.05,
              headRect.top + headRect.height * 0.29)
          ..quadraticBezierTo(
            cx + size.width * 0.04,
            headRect.top + headRect.height * 0.41,
            cx - size.width * 0.03,
            headRect.top + headRect.height * 0.29,
          )
          ..lineTo(headRect.left + size.width * 0.05,
              headRect.top + headRect.height * 0.48)
          ..close();
        break;
      case 2:
        hairPath
          ..moveTo(headRect.left - size.width * 0.03, headRect.top + headRect.height * 0.48)
          ..quadraticBezierTo(cx - size.width * 0.10, headRect.top - size.height * 0.05,
              headRect.right + size.width * 0.02, headRect.top + headRect.height * 0.25)
          ..lineTo(headRect.right - size.width * 0.02, headRect.top + headRect.height * 0.44)
          ..quadraticBezierTo(cx + size.width * 0.05, headRect.top + headRect.height * 0.29,
              headRect.left + size.width * 0.05, headRect.top + headRect.height * 0.45)
          ..close();
        break;
      case 3:
        hairPath
          ..moveTo(headRect.left, headRect.top + headRect.height * 0.35)
          ..quadraticBezierTo(cx, headRect.top - size.height * 0.08,
              headRect.right, headRect.top + headRect.height * 0.35)
          ..lineTo(headRect.right, headRect.top + headRect.height * 0.48)
          ..lineTo(cx, headRect.top + headRect.height * 0.34)
          ..lineTo(headRect.left, headRect.top + headRect.height * 0.48)
          ..close();
        break;
      case 4:
        hairPath
          ..moveTo(headRect.left - size.width * 0.01,
              headRect.top + headRect.height * 0.49)
          ..cubicTo(
            headRect.left,
            headRect.top + headRect.height * 0.12,
            cx - size.width * 0.16,
            headRect.top - size.height * 0.08,
            cx + size.width * 0.04,
            headRect.top - size.height * 0.05,
          )
          ..cubicTo(
            cx + size.width * 0.20,
            headRect.top - size.height * 0.03,
            headRect.right + size.width * 0.05,
            headRect.top + headRect.height * 0.18,
            headRect.right + size.width * 0.01,
            headRect.top + headRect.height * 0.46,
          )
          ..quadraticBezierTo(
            cx + size.width * 0.15,
            headRect.top + headRect.height * 0.31,
            cx + size.width * 0.03,
            headRect.top + headRect.height * 0.27,
          )
          ..quadraticBezierTo(
            cx - size.width * 0.11,
            headRect.top + headRect.height * 0.44,
            headRect.left + size.width * 0.08,
            headRect.top + headRect.height * 0.37,
          )
          ..close();
        break;
      case 5:
        hairPath
          ..moveTo(headRect.left - size.width * 0.02, headRect.top + headRect.height * 0.52)
          ..quadraticBezierTo(cx, headRect.top - size.height * 0.04,
              headRect.right + size.width * 0.02, headRect.top + headRect.height * 0.52)
          ..lineTo(headRect.right - size.width * 0.06, headRect.top + headRect.height * 0.30)
          ..lineTo(cx, headRect.top + headRect.height * 0.43)
          ..lineTo(headRect.left + size.width * 0.06, headRect.top + headRect.height * 0.30)
          ..close();
        break;
      case 6:
        hairPath
          ..moveTo(headRect.left - size.width * 0.12,
              headRect.top + headRect.height * 0.51)
          ..cubicTo(
            headRect.left - size.width * 0.18,
            headRect.top + headRect.height * 0.33,
            headRect.left - size.width * 0.04,
            headRect.top + headRect.height * 0.13,
            cx - size.width * 0.17,
            headRect.top + headRect.height * 0.04,
          )
          ..cubicTo(
            cx - size.width * 0.05,
            headRect.top - size.height * 0.12,
            cx + size.width * 0.07,
            headRect.top - size.height * 0.08,
            cx + size.width * 0.12,
            headRect.top + headRect.height * 0.06,
          )
          ..cubicTo(
            headRect.right + size.width * 0.07,
            headRect.top - size.height * 0.01,
            headRect.right + size.width * 0.18,
            headRect.top + headRect.height * 0.25,
            headRect.right + size.width * 0.11,
            headRect.top + headRect.height * 0.51,
          )
          ..lineTo(headRect.right - size.width * 0.04,
              headRect.top + headRect.height * 0.31)
          ..quadraticBezierTo(
            cx + size.width * 0.05,
            headRect.top + headRect.height * 0.43,
            cx,
            headRect.top + headRect.height * 0.31,
          )
          ..quadraticBezierTo(
            cx - size.width * 0.12,
            headRect.top + headRect.height * 0.46,
            headRect.left + size.width * 0.03,
            headRect.top + headRect.height * 0.31,
          )
          ..close();
        break;
      default:
        hairPath
          ..moveTo(headRect.left - size.width * 0.01, headRect.top + headRect.height * 0.52)
          ..quadraticBezierTo(cx, headRect.top - size.height * 0.04,
              headRect.right + size.width * 0.01, headRect.top + headRect.height * 0.52)
          ..lineTo(headRect.right - size.width * 0.03, headRect.top + headRect.height * 0.25)
          ..lineTo(headRect.left + size.width * 0.03, headRect.top + headRect.height * 0.25)
          ..close();
    }
    canvas.drawPath(hairPath, hairPaint);

    final eyeY = headRect.top + headRect.height * 0.58;
    final eyeOffset = size.width * 0.10;
    canvas.drawCircle(Offset(cx - eyeOffset, eyeY), size.width * 0.025, featurePaint);
    canvas.drawCircle(Offset(cx + eyeOffset, eyeY), size.width * 0.025, featurePaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, headRect.top + headRect.height * 0.72),
        width: size.width * 0.16,
        height: size.height * 0.10,
      ),
      0.15,
      math.pi - 0.3,
      false,
      featurePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniPersonPainter oldDelegate) {
    return oldDelegate.variant != variant;
  }
}

class _RibbonPiecePainter extends CustomPainter {
  const _RibbonPiecePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ribbonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.16, size.width, size.height * 0.68),
      Radius.circular(size.height * 0.12),
    );
    final shadow = Paint()
      ..color = const Color(0x1A4C1D3C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawRRect(ribbonRect.shift(const Offset(0, 1)), shadow);
    canvas.drawRRect(
      ribbonRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFB6C8),
            Color(0xFFEC4899),
            Color(0xFFBE185D),
          ],
          stops: [0, 0.52, 1],
        ).createShader(ribbonRect.outerRect),
    );
    canvas.drawRRect(
      ribbonRect,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 0.75
        ..style = PaintingStyle.stroke,
    );
    final cutPaint = Paint()
      ..color = const Color(0x4D831843)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(2, size.height * 0.22),
      Offset(2, size.height * 0.78),
      cutPaint,
    );
    canvas.drawLine(
      Offset(size.width - 2, size.height * 0.22),
      Offset(size.width - 2, size.height * 0.78),
      cutPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.35),
      Offset(size.width * 0.92, size.height * 0.35),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.68),
      Offset(size.width * 0.92, size.height * 0.68),
      Paint()
        ..color = const Color(0x55831343)
        ..strokeWidth = 0.75
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPiecePainter oldDelegate) => false;
}

/// A cut cord has a rounded, twisted surface rather than the flat sheen used
/// for a ribbon.  The three strands also make small pieces readable as string.
class _CordPiecePainter extends CustomPainter {
  const _CordPiecePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.5;
    final width = math.max(1.0, size.width - 8);
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF4D08A),
          Color(0xFFD9A441),
          Color(0xFFA76520),
        ],
        stops: [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(4, centerY - 6, width, 12))
      ..strokeWidth = size.height * 0.38
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(4, centerY), Offset(size.width - 4, centerY), base);

    final strand = Paint()
      ..color = const Color(0x99FFF3C4)
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var offset = 0.0; offset < size.width; offset += 9) {
      final segment = Path()
        ..moveTo(offset + 4, centerY - 2)
        ..quadraticBezierTo(offset + 8, centerY + 2.6, offset + 12, centerY - 2);
      canvas.drawPath(segment, strand);
    }

    final cutPaint = Paint()
      ..color = const Color(0x99A16207)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(4, centerY - size.height * 0.18),
      Offset(4, centerY + size.height * 0.18),
      cutPaint,
    );
    canvas.drawLine(
      Offset(size.width - 4, centerY - size.height * 0.18),
      Offset(size.width - 4, centerY + size.height * 0.18),
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CordPiecePainter oldDelegate) => false;
}

class _PencilPainter extends CustomPainter {
  const _PencilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-size.width * 0.5, -size.height * 0.5);

    final centerY = size.height * 0.52;
    final bodyLeft = size.width * 0.2;
    final bodyRight = size.width * 0.78;
    final bodyHeight = size.height * 0.36;
    final bodyRect = Rect.fromLTWH(
      bodyLeft,
      centerY - bodyHeight / 2,
      bodyRight - bodyLeft,
      bodyHeight,
    );

    final shadow = Paint()
      ..color = const Color(0x1F0F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect.shift(const Offset(0, 1)), const Radius.circular(2)),
      shadow,
    );

    final eraser = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.05,
        centerY - bodyHeight * 0.52,
        size.width * 0.16,
        bodyHeight * 1.04,
      ),
      Radius.circular(bodyHeight * 0.18),
    );
    canvas.drawRRect(eraser, Paint()..color = const Color(0xFFFCA5A5));
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.19,
        centerY - bodyHeight * 0.52,
        size.width * 0.04,
        bodyHeight * 1.04,
      ),
      Paint()..color = const Color(0xFFCBD5E1),
    );

    canvas.drawRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFF1A8),
            Color(0xFFFBBF24),
            Color(0xFFD97706),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(bodyRect),
    );
    canvas.drawLine(
      Offset(bodyLeft + 2, centerY - bodyHeight * 0.18),
      Offset(bodyRight - 2, centerY - bodyHeight * 0.18),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(bodyLeft + 2, centerY + bodyHeight * 0.28),
      Offset(bodyRight - 2, centerY + bodyHeight * 0.28),
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );

    final wood = Path()
      ..moveTo(bodyRight, centerY - bodyHeight / 2)
      ..lineTo(size.width * 0.94, centerY)
      ..lineTo(bodyRight, centerY + bodyHeight / 2)
      ..close();
    canvas.drawPath(wood, Paint()..color = const Color(0xFFF6D6A7));
    final lead = Path()
      ..moveTo(size.width * 0.94, centerY)
      ..lineTo(size.width * 0.82, centerY - bodyHeight * 0.32)
      ..lineTo(size.width * 0.82, centerY + bodyHeight * 0.32)
      ..close();
    canvas.drawPath(lead, Paint()..color = const Color(0xFF111827));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PencilPainter oldDelegate) => false;
}

class _ApplePainter extends CustomPainter {
  const _ApplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final shadow = Paint()
      ..color = const Color(0x240F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, s * 0.05),
        width: s * 0.72,
        height: s * 0.24,
      ),
      shadow,
    );

    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.26)
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.22,
        size.width * 0.34,
        size.height * 0.2,
        size.width * 0.27,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.45,
        size.width * 0.17,
        size.height * 0.86,
        size.width * 0.43,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.89,
        size.width * 0.53,
        size.height * 0.89,
        size.width * 0.57,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.86,
        size.width * 0.92,
        size.height * 0.45,
        size.width * 0.73,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.2,
        size.width * 0.57,
        size.height * 0.22,
        size.width * 0.5,
        size.height * 0.26,
      )
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFFF7A45),
            Color(0xFFF43F2A),
            Color(0xFFB91C1C),
          ],
          stops: [0, 0.62, 1],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final dimplePaint = Paint()..color = const Color(0x220F172A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.27),
        width: s * 0.22,
        height: s * 0.1,
      ),
      dimplePaint,
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    final stemPaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.25),
      Offset(size.width * 0.58, size.height * 0.08),
      stemPaint,
    );
    final leaf = Path()
      ..moveTo(size.width * 0.58, size.height * 0.16)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.02,
        size.width * 0.84,
        size.height * 0.11,
        size.width * 0.72,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.27,
        size.width * 0.6,
        size.height * 0.22,
        size.width * 0.58,
        size.height * 0.16,
      );
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFF86EFAC), Color(0xFF15803D)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.44),
        width: s * 0.12,
        height: s * 0.22,
      ),
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _ApplePainter oldDelegate) => false;
}

class _StrawberryPainter extends CustomPainter {
  const _StrawberryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.97)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.74,
        size.width * 0.12,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.2,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.3,
        size.width * 0.85,
        size.height * 0.74,
        size.width * 0.5,
        size.height * 0.97,
      )
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.95,
          colors: const [
            Color(0xFFFF6B6B),
            Color(0xFFEF4444),
            Color(0xFFB91C1C),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final seedPaint = Paint()..color = const Color(0xFFEFE7B0);
    for (final p in const [
      Offset(0.42, 0.46),
      Offset(0.58, 0.47),
      Offset(0.34, 0.6),
      Offset(0.5, 0.63),
      Offset(0.66, 0.6),
      Offset(0.43, 0.76),
      Offset(0.57, 0.77),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * p.dx, size.height * p.dy),
          width: s * 0.018,
          height: s * 0.038,
        ),
        seedPaint,
      );
    }

    final leafPaint = Paint()..color = const Color(0xFF15803D);
    for (final angle in [-0.75, -0.35, 0.05, 0.45, 0.85]) {
      final path = Path()
        ..moveTo(size.width * 0.5, size.height * 0.2)
        ..lineTo(
          size.width * (0.5 + math.cos(angle) * 0.28),
          size.height * (0.19 + math.sin(angle).abs() * 0.07),
        )
        ..lineTo(
          size.width * (0.5 + math.cos(angle) * 0.11),
          size.height * 0.3,
        )
        ..close();
      canvas.drawPath(path, leafPaint);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.45),
        width: s * 0.1,
        height: s * 0.18,
      ),
      Paint()..color = const Color(0x55FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _StrawberryPainter oldDelegate) => false;
}

class _CookiePainter extends CustomPainter {
  const _CookiePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final shadow = Paint()
      ..color = const Color(0x220F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawCircle(center.translate(0, 1.4), radius, shadow);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: const [
            Color(0xFFFDE68A),
            Color(0xFFF59E0B),
            Color(0xFFB45309),
          ],
          stops: [0.0, 0.68, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final chipPaint = Paint()..color = const Color(0xFF7C2D12);
    for (final p in const [
      Offset(0.36, 0.36),
      Offset(0.58, 0.32),
      Offset(0.68, 0.52),
      Offset(0.45, 0.59),
      Offset(0.31, 0.67),
    ]) {
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        radius * 0.13,
        chipPaint,
      );
    }
    canvas.drawCircle(
      center.translate(-radius * 0.35, -radius * 0.32),
      radius * 0.16,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _CookiePainter oldDelegate) => false;
}

class _CandyPainter extends CustomPainter {
  const _CandyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bodyWidth = size.width * 0.48;
    final bodyHeight = size.height * 0.38;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: bodyWidth, height: bodyHeight),
      Radius.circular(bodyHeight / 2),
    );
    final leftWrapper = Path()
      ..moveTo(center.dx - bodyWidth * 0.42, center.dy)
      ..lineTo(size.width * 0.12, size.height * 0.28)
      ..lineTo(size.width * 0.12, size.height * 0.72)
      ..close();
    final rightWrapper = Path()
      ..moveTo(center.dx + bodyWidth * 0.42, center.dy)
      ..lineTo(size.width * 0.88, size.height * 0.28)
      ..lineTo(size.width * 0.88, size.height * 0.72)
      ..close();

    final shadow = Paint()
      ..color = const Color(0x1F0F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawRRect(bodyRect.shift(const Offset(0, 1.2)), shadow);

    final wrapperPaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawPath(leftWrapper, wrapperPaint);
    canvas.drawPath(rightWrapper, wrapperPaint);
    final wrapperLinePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leftWrapper, wrapperLinePaint);
    canvas.drawPath(rightWrapper, wrapperLinePaint);

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFFFCA5A5), Color(0xFFEF4444)],
        ).createShader(bodyRect.outerRect),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-bodyWidth * 0.14, -bodyHeight * 0.18),
        width: bodyWidth * 0.34,
        height: bodyHeight * 0.28,
      ),
      Paint()..color = const Color(0x80FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _CandyPainter oldDelegate) => false;
}

class _MarblePainter extends CustomPainter {
  const _MarblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.39;

    canvas.drawCircle(
      center.translate(0, 1.4),
      radius,
      Paint()
        ..color = const Color(0x220F172A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    final baseRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.95,
          colors: const [
            Color(0xFFE0F7FA),
            Color(0xFF67E8F9),
            Color(0xFF0891B2),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(baseRect),
    );

    final swirlPaint = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final swirl = Path()
      ..moveTo(center.dx - radius * 0.55, center.dy + radius * 0.08)
      ..cubicTo(
        center.dx - radius * 0.2,
        center.dy - radius * 0.42,
        center.dx + radius * 0.24,
        center.dy + radius * 0.44,
        center.dx + radius * 0.58,
        center.dy - radius * 0.08,
      );
    canvas.drawPath(swirl, swirlPaint);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center.translate(-radius * 0.32, -radius * 0.36),
      radius * 0.18,
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _MarblePainter oldDelegate) => false;
}

class _MiniCardPainter extends CustomPainter {
  const _MiniCardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x1A0F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.22,
        size.width * 0.46,
        size.height * 0.58,
      ),
      Radius.circular(size.width * 0.08),
    );
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.16,
        size.width * 0.46,
        size.height * 0.58,
      ),
      Radius.circular(size.width * 0.08),
    );

    canvas.drawRRect(backRect.shift(const Offset(0, 1)), shadow);
    canvas.drawRRect(
      backRect,
      Paint()..color = const Color(0xFFE0F2FE),
    );
    canvas.drawRRect(
      backRect,
      Paint()
        ..color = const Color(0xFF7DD3FC)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    canvas.drawRRect(frontRect.shift(const Offset(0, 1)), shadow);
    canvas.drawRRect(
      frontRect,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawRRect(
      frontRect,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(frontRect.left + size.width * 0.1, frontRect.top + size.height * 0.18),
      Offset(frontRect.right - size.width * 0.08, frontRect.top + size.height * 0.18),
      Paint()
        ..color = const Color(0xFFBAE6FD)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniCardPainter oldDelegate) => false;
}

class _StickerPainter extends CustomPainter {
  const _StickerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final shadowPaint = Paint()
      ..color = const Color(0x1F0F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center.translate(0, 1.6), radius, shadowPaint);

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: const [Color(0xFF93C5FD), Color(0xFF3B82F6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    final glossPaint = Paint()..color = const Color(0x99FFFFFF);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.28, -radius * 0.34),
        width: radius * 0.72,
        height: radius * 0.38,
      ),
      glossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StickerPainter oldDelegate) => false;
}
