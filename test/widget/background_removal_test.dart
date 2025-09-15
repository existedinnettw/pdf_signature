import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/signature/widgets/image_editor_dialog.dart';
import 'package:pdf_signature/domain/models/model.dart' as domain;

void main() {
  group('ImageEditorDialog Background Removal', () {
    test('should create ImageEditorDialog with background removal enabled', () {
      // Create test data
      final testAsset = domain.SignatureAsset(
        bytes: Uint8List(0),
        name: 'test',
      );
      final testGraphicAdjust = domain.GraphicAdjust(bgRemoval: true);

      // Create ImageEditorDialog instance
      final dialog = ImageEditorDialog(
        asset: testAsset,
        initialRotation: 0.0,
        initialGraphicAdjust: testGraphicAdjust,
      );

      // Verify that the dialog is created successfully
      expect(dialog, isNotNull);
      expect(dialog.asset, equals(testAsset));
      expect(
        dialog.initialGraphicAdjust.bgRemoval,
        isTrue,
        reason: 'Background removal should be enabled',
      );
    });

    test(
      'should create ImageEditorDialog with background removal disabled',
      () {
        // Create test data
        final testAsset = domain.SignatureAsset(
          bytes: Uint8List(0),
          name: 'test',
        );
        final testGraphicAdjust = domain.GraphicAdjust(bgRemoval: false);

        // Create ImageEditorDialog instance
        final dialog = ImageEditorDialog(
          asset: testAsset,
          initialRotation: 0.0,
          initialGraphicAdjust: testGraphicAdjust,
        );

        // Verify that the dialog is created successfully
        expect(dialog, isNotNull);
        expect(dialog.asset, equals(testAsset));
        expect(
          dialog.initialGraphicAdjust.bgRemoval,
          isFalse,
          reason: 'Background removal should be disabled',
        );
      },
    );
  });
}
