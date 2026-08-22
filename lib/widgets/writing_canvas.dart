import 'dart:ui' as ui show Picture, PictureRecorder;

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
  static const double _minPointDistanceSquared = 16;

  final List<_CanvasPoint> _points = [];
  final ValueNotifier<int> _paintRevision = ValueNotifier<int>(0);
  ui.Picture? _completedPicture;
  _CanvasTool _tool = _CanvasTool.pen;
  int _activeStrokeStart = 0;

  @override
  void dispose() {
    _completedPicture?.dispose();
    _paintRevision.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    final wasEmpty = _points.isEmpty;
    _activeStrokeStart = _points.length;
    _points.add(_CanvasPoint(point, _tool));
    _requestPaint();
    if (wasEmpty) {
      setState(() {});
    }
  }

  void _appendPoint(Offset point) {
    final previousPoint = _points.isEmpty ? null : _points.last.offset;
    if (previousPoint != null &&
        (point - previousPoint).distanceSquared < _minPointDistanceSquared) {
      return;
    }

    _points.add(_CanvasPoint(point, _tool));
    _requestPaint();
  }

  void _endStroke() {
    if (_points.isEmpty || _points.last.offset == null) return;

    _points.add(_CanvasPoint.separator());
    _rebuildCompletedPicture();
    _activeStrokeStart = _points.length;
    _requestPaint();
  }

  void _clear() {
    if (_points.isEmpty) return;

    _points.clear();
    _completedPicture?.dispose();
    _completedPicture = null;
    _activeStrokeStart = 0;
    _requestPaint();
    setState(() {});
  }

  void _requestPaint() {
    _paintRevision.value++;
  }

  void _rebuildCompletedPicture() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _StrokeRenderer.drawAll(canvas, _points);
    _completedPicture?.dispose();
    _completedPicture = recorder.endRecording();
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 8),
              Flexible(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ToolButton(
                      selected: _tool == _CanvasTool.pen,
                      icon: Icons.edit_rounded,
                      tooltip: 'ペン',
                      onTap: () => _setTool(_CanvasTool.pen),
                    ),
                    _ToolButton(
                      selected: _tool == _CanvasTool.eraser,
                      icon: Icons.cleaning_services_rounded,
                      tooltip: '消しゴム',
                      onTap: () => _setTool(_CanvasTool.eraser),
                    ),
                    _ToolButton(
                      selected: false,
                      icon: Icons.delete_outline_rounded,
                      tooltip: '全消去',
                      onTap: _points.isEmpty ? null : _clear,
                    ),
                    if (widget.showCloseButton)
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.42),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: RepaintBoundary(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _startStroke(event.localPosition),
                  onPointerMove: (event) => _appendPoint(event.localPosition),
                  onPointerUp: (_) => _endStroke(),
                  onPointerCancel: (_) => _endStroke(),
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      completedPicture: _completedPicture,
                      points: _points,
                      activeStrokeStartIndex: _activeStrokeStart,
                      repaint: _paintRevision,
                      penWidth: penWidth,
                      eraserWidth: eraserWidth,
                    ),
                    child: const SizedBox.expand(),
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
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.selected,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor:
            selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
        foregroundColor: selected ? Colors.white : const Color(0xFF111827),
        disabledBackgroundColor: const Color(0xFFF3F4F6),
        disabledForegroundColor: const Color(0xFF9CA3AF),
        minimumSize: const Size(52, 52),
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

abstract final class _StrokeRenderer {
  static void drawAll(Canvas canvas, List<_CanvasPoint> points) {
    drawRange(canvas, points, 0, points.length, penWidth: 5, eraserWidth: 80);
  }

  static void drawRange(
    Canvas canvas,
    List<_CanvasPoint> points,
    int start,
    int end, {
    required double penWidth,
    required double eraserWidth,
  }) {
    for (var i = start; i < end - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current.offset == null) continue;

      final isEraser = current.tool == _CanvasTool.eraser;
      final width = isEraser ? eraserWidth : penWidth;
      final color = isEraser ? Colors.white : const Color(0xFF111827);

      if (next.offset == null) {
        canvas.drawCircle(
          current.offset!,
          width / 2,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawLine(
          current.offset!,
          next.offset!,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = width,
        );
      }
    }
  }
}

class _DrawingPainter extends CustomPainter {
  final ui.Picture? completedPicture;
  final List<_CanvasPoint> points;
  final int activeStrokeStartIndex;
  final double penWidth;
  final double eraserWidth;

  _DrawingPainter({
    required this.completedPicture,
    required this.points,
    required this.activeStrokeStartIndex,
    required Listenable repaint,
    required this.penWidth,
    required this.eraserWidth,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (completedPicture != null) {
      canvas.drawPicture(completedPicture!);
    }

    if (activeStrokeStartIndex < points.length) {
      _StrokeRenderer.drawRange(
        canvas,
        points,
        activeStrokeStartIndex,
        points.length,
        penWidth: penWidth,
        eraserWidth: eraserWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.completedPicture != completedPicture ||
        oldDelegate.points != points ||
        oldDelegate.activeStrokeStartIndex != activeStrokeStartIndex ||
        oldDelegate.penWidth != penWidth ||
        oldDelegate.eraserWidth != eraserWidth;
  }
}
