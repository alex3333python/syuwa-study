import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

class WritingCanvas extends StatefulWidget {
  const WritingCanvas({super.key});

  @override
  State<WritingCanvas> createState() => _WritingCanvasState();
}

class _WritingCanvasState extends State<WritingCanvas> {
  final List<Offset?> _points = [];

  void _startStroke(Offset point) {
    setState(() {
      _points.add(point);
    });
  }

  void _appendPoint(Offset point) {
    setState(() {
      _points.add(point);
    });
  }

  void _endStroke() {
    if (_points.isEmpty || _points.last == null) return;

    setState(() {
      _points.add(null);
    });
  }

  void _clear() {
    setState(_points.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ここに考えを書いてみよう',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _points.isEmpty ? null : _clear,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('消す'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      _startStroke(details.localPosition);
                    },
                    onPanUpdate: (details) {
                      _appendPoint(details.localPosition);
                    },
                    onPanEnd: (_) => _endStroke(),
                    onPanCancel: _endStroke,
                    child: CustomPaint(
                      painter: _WritingPainter(points: _points),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WritingPainter extends CustomPainter {
  final List<Offset?> points;

  const _WritingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    const gridGap = 36.0;

    for (double x = gridGap; x < size.width; x += gridGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = gridGap; y < size.height; y += gridGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF111827)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current == null) {
        continue;
      }

      if (next == null) {
        canvas.drawPoints(PointMode.points, [current], strokePaint);
      } else {
        canvas.drawLine(current, next, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
