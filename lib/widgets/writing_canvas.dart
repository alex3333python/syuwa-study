import 'dart:ui' as ui show Picture, PictureRecorder;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mutable holders so [CustomPainter(repaint:)] always paints current ink
/// without rebuilding the widget tree on every pointer move.
class _PictureSlot {
  ui.Picture? picture;
}

class _ActiveStrokeSlot {
  final Path path = Path();
  var isActive = false;
  _CanvasTool tool = _CanvasTool.pen;
}

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
  /// Skip micro-moves so path/draw stays light on Safari / CanvasKit.
  static const double _minPointDistanceSquared = 2.25; // 1.5px

  final List<_CanvasPoint> _points = [];
  final ValueNotifier<int> _paintRevision = ValueNotifier<int>(0);
  final _PictureSlot _completedSlot = _PictureSlot();
  final _ActiveStrokeSlot _activeSlot = _ActiveStrokeSlot();
  _CanvasTool _tool = _CanvasTool.pen;
  Size _canvasSize = Size.zero;
  Offset? _lastActivePoint;
  var _hasUsedEraser = false;

  @override
  void dispose() {
    _completedSlot.picture?.dispose();
    _paintRevision.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    final wasEmpty = _points.isEmpty;
    _activeSlot.path
      ..reset()
      ..moveTo(point.dx, point.dy);
    _activeSlot
      ..isActive = true
      ..tool = _tool;
    _lastActivePoint = point;
    _points.add(_CanvasPoint(point, _tool));
    if (_tool == _CanvasTool.eraser) {
      _hasUsedEraser = true;
    }
    _paintRevision.value++;
    if (wasEmpty) {
      setState(() {});
    }
  }

  void _appendPoint(Offset point) {
    if (_points.isEmpty || !_activeSlot.isActive || _lastActivePoint == null) {
      return;
    }

    final previous = _lastActivePoint!;
    if ((point - previous).distanceSquared < _minPointDistanceSquared) {
      return;
    }

    _activeSlot.path.lineTo(point.dx, point.dy);
    _lastActivePoint = point;
    _points.add(_CanvasPoint(point, _tool));
    _paintRevision.value++;
  }

  void _endStroke() {
    if (_points.isEmpty || _points.last.offset == null) return;
    if (!_activeSlot.isActive) return;

    _points.add(const _CanvasPoint.separator());
    _commitActiveStroke();
    _activeSlot
      ..isActive = false
      ..path.reset();
    _lastActivePoint = null;
    _paintRevision.value++;
  }

  void _clear() {
    if (_points.isEmpty && _completedSlot.picture == null) return;

    _points.clear();
    _activeSlot
      ..isActive = false
      ..path.reset();
    _lastActivePoint = null;
    _hasUsedEraser = false;
    _completedSlot.picture?.dispose();
    _completedSlot.picture = null;
    _paintRevision.value++;
    setState(() {});
  }

  void _commitActiveStroke() {
    if (_canvasSize == Size.zero || !_activeSlot.isActive) return;

    if (_hasUsedEraser) {
      _rebuildAllPoints();
      return;
    }

    // Fast path: stamp previous picture + just-finished pen stroke.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final previous = _completedSlot.picture;
    if (previous != null) {
      canvas.drawPicture(previous);
    }
    canvas.drawPath(
      _activeSlot.path,
      _StrokeRenderer.penPaint(penWidth: penWidth, antiAlias: !kIsWeb),
    );
    previous?.dispose();
    _completedSlot.picture = recorder.endRecording();
  }

  void _rebuildAllPoints() {
    if (_canvasSize == Size.zero) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Offset.zero & _canvasSize;

    canvas.saveLayer(bounds, Paint());
    _StrokeRenderer.drawRange(
      canvas,
      _points,
      0,
      _points.length,
      penWidth: penWidth,
      eraserWidth: eraserWidth,
      eraserUsesClear: true,
      antiAlias: !kIsWeb,
    );
    canvas.restore();

    _completedSlot.picture?.dispose();
    _completedSlot.picture = recorder.endRecording();
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
              color: Colors.white.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.42),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  if (_canvasSize != size) {
                    _canvasSize = size;
                    if (_points.isNotEmpty) {
                      _rebuildAllPoints();
                    }
                  }

                  return RepaintBoundary(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          _startStroke(event.localPosition),
                      onPointerMove: (event) {
                        if (event.buttons == 0) return;
                        _appendPoint(event.localPosition);
                      },
                      onPointerUp: (_) => _endStroke(),
                      onPointerCancel: (_) => _endStroke(),
                      child: CustomPaint(
                        isComplex: true,
                        willChange: true,
                        painter: _DrawingPainter(
                          completedSlot: _completedSlot,
                          activeSlot: _activeSlot,
                          canvasSize: size,
                          penWidth: penWidth,
                          eraserWidth: eraserWidth,
                          antiAlias: !kIsWeb,
                          repaint: _paintRevision,
                        ),
                        child: const SizedBox.expand(),
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
  static Paint penPaint({required double penWidth, required bool antiAlias}) {
    return Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = penWidth
      ..isAntiAlias = antiAlias;
  }

  static void drawRange(
    Canvas canvas,
    List<_CanvasPoint> points,
    int start,
    int end, {
    required double penWidth,
    required double eraserWidth,
    required bool eraserUsesClear,
    required bool antiAlias,
  }) {
    Path? path;
    _CanvasTool? pathTool;
    Offset? pathStart;
    var pathHasLine = false;

    void flushPath() {
      if (path == null || pathTool == null) return;

      final paint = _paintFor(
        pathTool!,
        penWidth: penWidth,
        eraserWidth: eraserWidth,
        eraserUsesClear: eraserUsesClear,
        antiAlias: antiAlias,
      );
      if (!pathHasLine && pathStart != null && pathTool == _CanvasTool.pen) {
        canvas.drawCircle(
          pathStart!,
          penWidth / 2,
          Paint()
            ..color = paint.color
            ..isAntiAlias = antiAlias,
        );
      } else {
        canvas.drawPath(path!, paint);
      }
      path = null;
      pathTool = null;
      pathStart = null;
      pathHasLine = false;
    }

    for (var i = start; i < end; i++) {
      final current = points[i];
      if (current.offset == null) {
        flushPath();
        continue;
      }

      if (path == null) {
        pathStart = current.offset;
        path = Path()..moveTo(current.offset!.dx, current.offset!.dy);
        pathTool = current.tool;
        continue;
      }

      if (pathTool != current.tool) {
        flushPath();
        pathStart = current.offset;
        path = Path()..moveTo(current.offset!.dx, current.offset!.dy);
        pathTool = current.tool;
        continue;
      }

      path!.lineTo(current.offset!.dx, current.offset!.dy);
      pathHasLine = true;
    }

    flushPath();
  }

  static Paint _paintFor(
    _CanvasTool tool, {
    required double penWidth,
    required double eraserWidth,
    required bool eraserUsesClear,
    required bool antiAlias,
  }) {
    if (tool == _CanvasTool.eraser) {
      if (eraserUsesClear) {
        return Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = eraserWidth
          ..isAntiAlias = antiAlias;
      }
      return Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = eraserWidth
        ..isAntiAlias = antiAlias;
    }

    return penPaint(penWidth: penWidth, antiAlias: antiAlias);
  }
}

class _DrawingPainter extends CustomPainter {
  final _PictureSlot completedSlot;
  final _ActiveStrokeSlot activeSlot;
  final Size canvasSize;
  final double penWidth;
  final double eraserWidth;
  final bool antiAlias;

  _DrawingPainter({
    required this.completedSlot,
    required this.activeSlot,
    required this.canvasSize,
    required this.penWidth,
    required this.eraserWidth,
    required this.antiAlias,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final completed = completedSlot.picture;
    final active = activeSlot.isActive ? activeSlot.path : null;
    final hasActiveEraser =
        active != null && activeSlot.tool == _CanvasTool.eraser;

    if (hasActiveEraser) {
      final bounds = Offset.zero & canvasSize;
      canvas.saveLayer(bounds, Paint());
      if (completed != null) {
        canvas.drawPicture(completed);
      }
      canvas.drawPath(
        active,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = eraserWidth
          ..isAntiAlias = antiAlias,
      );
      canvas.restore();
      return;
    }

    if (completed != null) {
      canvas.drawPicture(completed);
    }

    if (active != null) {
      canvas.drawPath(
        active,
        _StrokeRenderer.penPaint(penWidth: penWidth, antiAlias: antiAlias),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.completedSlot != completedSlot ||
        oldDelegate.activeSlot != activeSlot ||
        oldDelegate.canvasSize != canvasSize ||
        oldDelegate.penWidth != penWidth ||
        oldDelegate.eraserWidth != eraserWidth ||
        oldDelegate.antiAlias != antiAlias;
  }
}
