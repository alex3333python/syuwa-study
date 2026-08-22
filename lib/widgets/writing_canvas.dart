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

  final List<_CanvasPoint> _points = [];
  final ValueNotifier<int> _paintRevision = ValueNotifier<int>(0);
  ui.Picture? _completedPicture;
  _CanvasTool _tool = _CanvasTool.pen;
  Path? _activePath;
  Size _canvasSize = Size.zero;

  @override
  void dispose() {
    _completedPicture?.dispose();
    _paintRevision.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    final wasEmpty = _points.isEmpty;
    _points.add(_CanvasPoint(point, _tool));
    _activePath = Path()..moveTo(point.dx, point.dy);
    _requestPaint();
    if (wasEmpty) {
      setState(() {});
    }
  }

  void _appendPoint(Offset point) {
    if (_points.isEmpty) return;

    final previousPoint = _points.last.offset;
    if (previousPoint != null &&
        (point - previousPoint).distanceSquared < 1.5) {
      return;
    }

    _points.add(_CanvasPoint(point, _tool));
    _activePath?.lineTo(point.dx, point.dy);
    _requestPaint();
  }

  void _endStroke() {
    if (_points.isEmpty || _points.last.offset == null) return;

    _points.add(_CanvasPoint.separator());
    _activePath = null;
    _rebuildCompletedPicture();
    _requestPaint();
  }

  void _clear() {
    if (_points.isEmpty) return;

    _points.clear();
    _completedPicture?.dispose();
    _completedPicture = null;
    _activePath = null;
    _requestPaint();
    setState(() {});
  }

  void _requestPaint() {
    _paintRevision.value++;
  }

  bool _containsEraser(List<_CanvasPoint> points) {
    for (final point in points) {
      if (point.offset != null && point.tool == _CanvasTool.eraser) {
        return true;
      }
    }
    return false;
  }

  void _rebuildCompletedPicture() {
    if (_canvasSize == Size.zero) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Offset.zero & _canvasSize;
    final useClearEraser = _containsEraser(_points);

    if (useClearEraser) {
      canvas.saveLayer(bounds, Paint());
    }

    _StrokeRenderer.drawRange(
      canvas,
      _points,
      0,
      _points.length,
      penWidth: penWidth,
      eraserWidth: eraserWidth,
      eraserUsesClear: useClearEraser,
    );

    if (useClearEraser) {
      canvas.restore();
    }

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
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  if (_canvasSize != size) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _canvasSize == size) return;
                      setState(() => _canvasSize = size);
                      if (_points.isNotEmpty) {
                        _rebuildCompletedPicture();
                        _requestPaint();
                      }
                    });
                  }

                  return RepaintBoundary(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          _startStroke(event.localPosition),
                      onPointerMove: (event) =>
                          _appendPoint(event.localPosition),
                      onPointerUp: (_) => _endStroke(),
                      onPointerCancel: (_) => _endStroke(),
                      child: ListenableBuilder(
                        listenable: _paintRevision,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _DrawingPainter(
                              completedPicture: _completedPicture,
                              activePath: _activePath,
                              activeTool: _tool,
                              canvasSize: size,
                              penWidth: penWidth,
                              eraserWidth: eraserWidth,
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
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
  static void drawRange(
    Canvas canvas,
    List<_CanvasPoint> points,
    int start,
    int end, {
    required double penWidth,
    required double eraserWidth,
    required bool eraserUsesClear,
  }) {
    Path? path;
    _CanvasTool? pathTool;

    void flushPath() {
      if (path == null || pathTool == null) return;

      final Paint paint;
      if (pathTool == _CanvasTool.eraser) {
        if (eraserUsesClear) {
          paint = Paint()
            ..blendMode = BlendMode.clear
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = eraserWidth
            ..isAntiAlias = true;
        } else {
          paint = Paint()
            ..color = Colors.white.withValues(alpha: 0.32)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = eraserWidth
            ..isAntiAlias = true;
        }
      } else {
        paint = Paint()
          ..color = const Color(0xFF111827)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = penWidth
          ..isAntiAlias = true;
      }

      canvas.drawPath(path!, paint);
      path = null;
      pathTool = null;
    }

    for (var i = start; i < end; i++) {
      final current = points[i];
      if (current.offset == null) {
        flushPath();
        continue;
      }

      if (path == null) {
        path = Path()..moveTo(current.offset!.dx, current.offset!.dy);
        pathTool = current.tool;
        continue;
      }

      if (pathTool != current.tool) {
        flushPath();
        path = Path()..moveTo(current.offset!.dx, current.offset!.dy);
        pathTool = current.tool;
        continue;
      }

      path!.lineTo(current.offset!.dx, current.offset!.dy);
    }

    flushPath();
  }
}

class _DrawingPainter extends CustomPainter {
  final ui.Picture? completedPicture;
  final Path? activePath;
  final _CanvasTool activeTool;
  final Size canvasSize;
  final double penWidth;
  final double eraserWidth;

  static final Paint _penPaint = Paint()
    ..color = const Color(0xFF111827)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  static final Paint _eraserClearPaint = Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  _DrawingPainter({
    required this.completedPicture,
    required this.activePath,
    required this.activeTool,
    required this.canvasSize,
    required this.penWidth,
    required this.eraserWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hasActiveEraser =
        activePath != null && activeTool == _CanvasTool.eraser;

    if (hasActiveEraser) {
      final bounds = Offset.zero & canvasSize;
      canvas.saveLayer(bounds, Paint());
      if (completedPicture != null) {
        canvas.drawPicture(completedPicture!);
      }
      canvas.drawPath(
        activePath!,
        _eraserClearPaint..strokeWidth = eraserWidth,
      );
      canvas.restore();
      return;
    }

    if (completedPicture != null) {
      canvas.drawPicture(completedPicture!);
    }

    if (activePath != null) {
      canvas.drawPath(activePath!, _penPaint..strokeWidth = penWidth);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.completedPicture != completedPicture ||
        oldDelegate.activePath != activePath ||
        oldDelegate.activeTool != activeTool ||
        oldDelegate.canvasSize != canvasSize ||
        oldDelegate.penWidth != penWidth ||
        oldDelegate.eraserWidth != eraserWidth;
  }
}
