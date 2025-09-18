import 'package:flutter/material.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/model.dart';
import '../../signature/widgets/rotated_signature_image.dart';
import '../../signature/view_model/signature_view_model.dart';
import '../view_model/pdf_view_model.dart';

/// Minimal overlay widget for rendering a placed signature.
class SignatureOverlay extends ConsumerWidget {
  const SignatureOverlay({
    super.key,
    required this.pageSize,
    required this.rect,
    required this.placement,
    required this.placedIndex,
    required this.pageNumber,
  });

  final Size pageSize; // not used directly, kept for API symmetry
  final Rect rect; // normalized 0..1 values (left, top, width, height)
  final SignaturePlacement placement;
  final int placedIndex;
  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processedBytes = ref
        .watch(signatureViewModelProvider)
        .getProcessedBytes(placement.asset, placement.graphicAdjust);
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageW = constraints.maxWidth;
        final pageH = constraints.maxHeight;
        final rectPx = Rect.fromLTWH(
          rect.left * pageW,
          rect.top * pageH,
          rect.width * pageW,
          rect.height * pageH,
        );

        return Stack(
          children: [
            TransformableBox(
              key: Key('placed_signature_$placedIndex'),
              rect: rectPx,
              flip: Flip.none,
              // Keep the box within page bounds
              clampingRect: Rect.fromLTWH(0, 0, pageW, pageH),
              // Disable flips for signatures to avoid mirrored signatures
              allowFlippingWhileResizing: false,
              allowContentFlipping: false,
              onChanged: (result, details) {
                final r = result.rect;
                // Persist as normalized rect (0..1)
                final newRect = Rect.fromLTWH(
                  (r.left / pageW).clamp(0.0, 1.0),
                  (r.top / pageH).clamp(0.0, 1.0),
                  (r.width / pageW).clamp(0.0, 1.0),
                  (r.height / pageH).clamp(0.0, 1.0),
                );
                ref
                    .read(pdfViewModelProvider.notifier)
                    .updatePlacementRect(
                      page: pageNumber,
                      index: placedIndex,
                      rect: newRect,
                    );
              },
              // Keep default handles; you can customize later if needed
              contentBuilder:
                  (context, boxRect, flip) => DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: SizedBox(
                      width: boxRect.width,
                      height: boxRect.height,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RotatedSignatureImage(
                          bytes: processedBytes,
                          rotationDeg: placement.rotationDeg,
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}
