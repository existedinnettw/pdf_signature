import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pdf_signature/ui/features/signature/widgets/rotated_signature_image.dart';

/// Generates a simple solid-color PNG with given width/height.
Uint8List makePng({required int w, required int h}) {
  final im = img.Image(width: w, height: h);
  // Fill with opaque white
  img.fill(im, color: img.ColorRgba8(255, 255, 255, 255));
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  testWidgets('4:3 image rotated -90 deg scales to 3/4', (tester) async {
    // 4:3 aspect image -> width/height = 4/3
    final bytes = makePng(w: 400, h: 300);

    // Pump widget under a fixed-size parent so Transform.scale is applied
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 150, // same aspect as image bounds (4:3)
              child: RotatedSignatureImage(
                bytes: bytes,
                rotationDeg: -90,
                enableAngleAwareScale: true,
                intrinsicAspectRatio: 4 / 3,
                fit: BoxFit.contain,
                wrapInRepaintBoundary: false, // make Transform visible
              ),
            ),
          ),
        ),
      ),
    );

    // Find the Transform widget that applies the scale (the outer Transform.scale)
    final transformFinder = find.byType(Transform);
    expect(transformFinder, findsWidgets);

    // Among the Transforms, we expect one to be a scale-only matrix.
    // Grab the first Transform and assert the scale on x (m4x4 matrix) equals 0.75.
    Transform? scaleTransform;
    for (final e in tester.widgetList<Transform>(transformFinder)) {
      final m = e.transform.storage;
      // A scale-only matrix will have m[0] and m[5] as scale factors on x/y, with zeros elsewhere (except last row/column)
      // Also rotation transform will have off-diagonal terms; we want the one with zeros in 1,4 and 4,1 positions approximately.
      final isLikelyScale =
          (m[1].abs() < 1e-6) &&
          (m[4].abs() < 1e-6) &&
          (m[12].abs() < 1e-6) &&
          (m[13].abs() < 1e-6);
      if (isLikelyScale) {
        scaleTransform = e;
        break;
      }
    }
    expect(scaleTransform, isNotNull, reason: 'Scale Transform not found');

    final scale = scaleTransform!.transform.storage[0];
    expect(
      (scale - 0.75).abs() < 1e-6,
      isTrue,
      reason: 'Expected scale 0.75 for 4:3 rotated -90°',
    );
  });
}
