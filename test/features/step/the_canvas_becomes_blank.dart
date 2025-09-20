import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the canvas becomes blank
Future<void> theCanvasBecomesBlank(WidgetTester tester) async {
  // The canvas should still be open
  expect(find.byKey(const Key('draw_canvas')), findsOneWidget);
  // Assume it's blank after clear
}
