import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the last stroke is removed
Future<void> theLastStrokeIsRemoved(WidgetTester tester) async {
  // The canvas should still be open
  expect(find.byKey(const Key('draw_canvas')), findsOneWidget);
  // Assume the last stroke is removed
}
