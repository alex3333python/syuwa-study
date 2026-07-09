import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

class WritingCanvas extends StatefulWidget {
  final double height;
  final String title;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const WritingCanvas({
    super.key,
    this.height = 180,
    this.title = 'ここに考えを書いてみよう',
    this.onClose,
    this.showCloseButton = false,
  });

  @override
  State<WritingCanvas> createState() => _WritingCanvasState();
}

class _WritingCanvasState extends State<WritingCanvas> {
  static const double penWidth = 5;
  static const double eraserWidth = 80;

  final List<_CanvasPoint> _points = [];
  final ValueNotifier<int> _paintRevision = ValueNotifier<int>(0);
  _CanvasTool _tool = _CanvasTool.pen;

  @override
  void dispose() {
    _paintRevision.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    final wasEmpty = _points.isEmpty;
    _points.add(_CanvasPoint(point, _tool));
    _requestPaint();
    if (wasEmpty) {
      setState(() {});
    }
  }

  void _appendPoint(Offset point) {
    final previousPoint = _points.isEmpty ? null : _points.last.offset;
    if (previousPoint != null && (point - previousPoint).distanceSquared < 4) {
      return;
    }

    _points.add(_CanvasPoint(point, _tool));
    _requestPaint();
  }

  void _endStroke() {
    if (_points.isEmpty || _points.last.offset == null) return;

    _points.add(_CanvasPoint.separator());
    _requestPaint();
  }

  void _clear() {
    if (_points.isEmpty) return;

    _points.clear();
    _requestPaint();
    setState(() {});
  }

  void _requestPaint() {
    _paintRevision.value++;
  }

  void _setTool(_CanvasTool tool) {
    setState(() {
      _tool = tool;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withValues(alpha: 0.48),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ToolButton(
                selected: _tool == _CanvasTool.pen,
                icon: Icons.edit_rounded,
                label: 'ペン',
                onTap: () => _setTool(_CanvasTool.pen),
              ),
              const SizedBox(width: 10),
              _ToolButton(
                selected: _tool == _CanvasTool.eraser,
                icon: Icons.cleaning_services_rounded,
                label: '消しゴム',
                onTap: () => _setTool(_CanvasTool.eraser),
              ),
              const SizedBox(width: 10),
              _ToolButton(
                selected: false,
                icon: Icons.delete_outline_rounded,
                label: '全消去',
                onTap: _points.isEmpty ? null : _clear,
              ),
              if (widget.showCloseButton) ...[
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '閉じる',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(52, 52),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.42),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: RepaintBoundary(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => _startStroke(details.localPosition),
                  onPanUpdate: (details) => _appendPoint(details.localPosition),
                  onPanEnd: (_) => _endStroke(),
                  onPanCancel: _endStroke,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: const _GridPaperPainter(),
                        child: const SizedBox.expand(),
                      ),
                      CustomPaint(
                        painter: _DrawingPainter(
                          points: _points,
                          repaint: _paintRevision,
                          penWidth: penWidth,
                          eraserWidth: eraserWidth,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFF2563EB)
            : const Color(0xFFE5E7EB),
        foregroundColor: selected ? Colors.white : const Color(0xFF111827),
        disabledBackgroundColor: const Color(0xFFF3F4F6),
        disabledForegroundColor: const Color(0xFF9CA3AF),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }
}

enum _CanvasTool { pen, eraser }

class _CanvasPoint {
  final Offset? offset;
  final _CanvasTool tool;

  const _CanvasPoint(this.offset, this.tool);

  const _CanvasPoint.separator() : offset = null, tool = _CanvasTool.pen;
}

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant _GridPaperPainter oldDelegate) => false;
}

class _DrawingPainter extends CustomPainter {
  final List<_CanvasPoint> points;
  final double penWidth;
  final double eraserWidth;

  _DrawingPainter({
    required this.points,
    required Listenable repaint,
    required this.penWidth,
    required this.eraserWidth,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current.offset == null) {
        continue;
      }

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF111827)
        ..blendMode = current.tool == _CanvasTool.eraser
            ? BlendMode.clear
            : BlendMode.srcOver
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = current.tool == _CanvasTool.eraser
            ? eraserWidth
            : penWidth;

      if (next.offset == null) {
        canvas.drawPoints(PointMode.points, [current.offset!], strokePaint);
      } else {
        canvas.drawLine(current.offset!, next.offset!, strokePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.penWidth != penWidth ||
        oldDelegate.eraserWidth != eraserWidth;
  }
}
