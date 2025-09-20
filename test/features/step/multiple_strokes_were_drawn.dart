import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../_test_helper.dart';
import '_world.dart';

/// Usage: multiple strokes were drawn
Future<void> multipleStrokesWereDrawn(WidgetTester tester) async {
  // Open the draw dialog
  if (find.byType(MaterialApp).evaluate().isEmpty) {
    final container = await pumpApp(tester);
    TestWorld.container = container;
  }
  expect(find.byKey(const Key('btn_drawer_draw_signature')), findsOneWidget);
  await tester.tap(find.byKey(const Key('btn_drawer_draw_signature')));
  await tester.pumpAndSettle();

  // Draw multiple strokes
  final canvas = find.byKey(const Key('hand_signature_pad'));
  expect(canvas, findsOneWidget);

  // First stroke
  await tester.drag(canvas, const Offset(50, 50));
  await tester.drag(canvas, const Offset(100, 100));

  // Second stroke
  await tester.drag(canvas, const Offset(200, 200));
  await tester.drag(canvas, const Offset(250, 250));
}
