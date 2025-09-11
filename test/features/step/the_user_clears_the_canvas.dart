import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the user clears the canvas
Future<void> theUserClearsTheCanvas(WidgetTester tester) async {
  // Tap the clear button
  await tester.tap(find.byKey(const Key('btn_canvas_clear')));
  await tester.pumpAndSettle();
}
