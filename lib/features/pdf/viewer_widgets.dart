part of 'viewer.dart';

class DrawCanvas extends StatefulWidget {
  const DrawCanvas({super.key, required this.strokes});
  final List<List<Offset>> strokes;

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class _DrawCanvasState extends State<DrawCanvas> {
  late List<List<Offset>> _strokes;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _strokes = widget.strokes.map((s) => List.of(s)).toList();
  }

  void _startStroke(Offset localPosition) {
    setState(() => _strokes.add([localPosition]));
  }

  void _extendStroke(Offset localPosition) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.add(localPosition));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ElevatedButton(
                  key: const Key('btn_canvas_confirm'),
                  onPressed: () => Navigator.of(context).pop(_strokes),
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('btn_canvas_undo'),
                  onPressed: _undo,
                  child: const Text('Undo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('btn_canvas_clear'),
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('draw_canvas'),
              height: 240,
              child: Focus(
                // prevent text selection focus stealing on desktop
                canRequestFocus: false,
                child: Listener(
                  key: _canvasKey,
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    final box =
                        _canvasKey.currentContext!.findRenderObject()
                            as RenderBox;
                    _startStroke(box.globalToLocal(e.position));
                  },
                  onPointerMove: (e) {
                    final box =
                        _canvasKey.currentContext!.findRenderObject()
                            as RenderBox;
                    _extendStroke(box.globalToLocal(e.position));
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                    ),
                    child: CustomPaint(painter: StrokesPainter(_strokes)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  StrokesPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      for (int i = 1; i < s.length; i++) {
        canvas.drawLine(s[i - 1], s[i], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokesPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
