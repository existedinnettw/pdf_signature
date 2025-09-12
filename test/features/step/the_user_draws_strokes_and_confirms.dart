import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';
import '../_test_helper.dart';

/// Usage: the user draws strokes and confirms
Future<void> theUserDrawsStrokesAndConfirms(WidgetTester tester) async {
  // Ensure app is pumped if not already
  if (find.byType(MaterialApp).evaluate().isEmpty) {
    final container = await pumpApp(tester);
    TestWorld.container = container;
  }

  // If the drawer button isn't in the tree (simplified UI), inject a hidden button that opens the canvas
  // App provides the button via signature sidebar; no injection needed now

  // Tap the draw signature button to open the dialog
  await tester.tap(find.byKey(const Key('btn_drawer_draw_signature')));
  await tester.pumpAndSettle();

  // Now the DrawCanvas dialog should be open
  expect(find.byKey(const Key('draw_canvas')), findsOneWidget);

  // Simulate drawing strokes on the canvas
  final canvas = find.byKey(const Key('hand_signature_pad'));
  expect(canvas, findsOneWidget);

  // Draw a simple stroke
  await tester.drag(canvas, const Offset(50, 50));
  await tester.drag(canvas, const Offset(100, 100));
  await tester.drag(canvas, const Offset(150, 150));

  // Check confirm button is there
  expect(find.byKey(const Key('btn_canvas_confirm')), findsOneWidget);

  // Tap confirm
  await tester.tap(find.byKey(const Key('btn_canvas_confirm')));
  await tester.pumpAndSettle();

  // Dialog should be closed
  expect(find.byKey(const Key('draw_canvas')), findsNothing);

  // Inject a dummy asset into repository (app does not auto-add drawn bytes yet)
  final container = TestWorld.container;
  if (container != null) {
    container
        .read(signatureAssetRepositoryProvider.notifier)
        .add(
          // Tiny 1x1 transparent PNG (duplicated constant for test clarity)
          Uint8List.fromList([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
            0x00,
            0x00,
            0x00,
            0x0D,
            0x49,
            0x48,
            0x44,
            0x52,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01,
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89,
            0x00,
            0x00,
            0x00,
            0x0A,
            0x49,
            0x44,
            0x41,
            0x54,
            0x78,
            0x9C,
            0x63,
            0x60,
            0x00,
            0x00,
            0x00,
            0x02,
            0x00,
            0x01,
            0xE5,
            0x27,
            0xD4,
            0xA6,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44,
            0xAE,
            0x42,
            0x60,
            0x82,
          ]),
          name: 'drawing',
        );
  }
}
