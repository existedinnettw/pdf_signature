import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart' as hand;

class DrawCanvas extends StatefulWidget {
  const DrawCanvas({
    super.key,
    this.control,
    this.onConfirm,
    this.debugBytesSink,
  });

  final hand.HandSignatureControl? control;
  final ValueChanged<Uint8List?>? onConfirm;
  // For tests: allows observing exported bytes without relying on Navigator
  @visibleForTesting
  final ValueNotifier<Uint8List?>? debugBytesSink;

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class _DrawCanvasState extends State<DrawCanvas> {
  late final hand.HandSignatureControl _control =
      widget.control ??
      hand.HandSignatureControl(
        initialSetup: const hand.SignaturePathSetup(
          threshold: 3.0,
          smoothRatio: 0.7,
          velocityRange: 2.0,
          pressureRatio: 0.0,
        ),
      );

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
                  onPressed: () async {
                    // Export signature to PNG bytes
                    final data = await _control.toImage(
                      color: Colors.black,
                      background: Colors.transparent,
                      fit: true,
                      width: 1024,
                      height: 512,
                    );
                    final bytes = data?.buffer.asUint8List();
                    widget.debugBytesSink?.value = bytes;
                    if (widget.onConfirm != null) {
                      widget.onConfirm!(bytes);
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop(bytes);
                      }
                    }
                  },
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('btn_canvas_undo'),
                  onPressed: () => _control.stepBack(),
                  child: const Text('Undo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('btn_canvas_clear'),
                  onPressed: () => _control.clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('draw_canvas'),
              height: math.max(MediaQuery.of(context).size.height * 0.6, 350),
              child: AspectRatio(
                aspectRatio: 10 / 3,
                child: Container(
                  constraints: const BoxConstraints.expand(),
                  color: Colors.white,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) {},
                    child: hand.HandSignature(
                      key: const Key('hand_signature_pad'),
                      control: _control,
                      drawer: const hand.ShapeSignatureDrawer(
                        color: Colors.black,
                        width: 1.5,
                        maxWidth: 6.0,
                      ),
                    ),
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
