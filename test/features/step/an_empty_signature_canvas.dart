import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../_test_helper.dart';
import '_world.dart';

/// Usage: an empty signature canvas
Future<void> anEmptySignatureCanvas(WidgetTester tester) async {
  // Pump the app so the signature drawer (and its draw button) exists.
  if (find.byType(MaterialApp).evaluate().isEmpty) {
    final container = await pumpApp(tester);
    TestWorld.container = container;
  }
  // The draw canvas should not be open initially
  expect(find.byKey(const Key('draw_canvas')), findsNothing);
  // Ensure the draw signature button is present
  expect(find.byKey(const Key('btn_drawer_draw_signature')), findsOneWidget);
}
