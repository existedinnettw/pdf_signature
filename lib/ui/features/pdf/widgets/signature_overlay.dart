import 'package:flutter/material.dart';
import '../../../../domain/models/model.dart';
import '../../signature/widgets/rotated_signature_image.dart';

/// Minimal overlay widget for rendering a placed signature.
class SignatureOverlay extends StatelessWidget {
  const SignatureOverlay({
    super.key,
    required this.pageSize,
    required this.rect,
    required this.placement,
    required this.placedIndex,
  });

  final Size pageSize; // not used directly, kept for API symmetry
  final Rect rect; // normalized 0..1 values (left, top, width, height)
  final SignaturePlacement placement;
  final int placedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = rect.left * constraints.maxWidth;
        final top = rect.top * constraints.maxHeight;
        final width = rect.width * constraints.maxWidth;
        final height = rect.height * constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RotatedSignatureImage(
                    bytes: placement.asset.bytes,
                    rotationDeg: placement.rotationDeg,
                    key: Key('placed_signature_$placedIndex'),
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
