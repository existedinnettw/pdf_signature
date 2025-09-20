import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../_test_helper.dart';
import '_world.dart';

/// Usage: a drawn signature exists in the canvas
Future<void> aDrawnSignatureExistsInTheCanvas(WidgetTester tester) async {
  // Tap the draw signature button to open the dialog
  if (find.byType(MaterialApp).evaluate().isEmpty) {
    final container = await pumpApp(tester);
    TestWorld.container = container;
  }
  // Ensure button exists
  expect(find.byKey(const Key('btn_drawer_draw_signature')), findsOneWidget);
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

  // Do not confirm, so the canvas has strokes but is not closed
}
