import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: an empty signature canvas
Future<void> anEmptySignatureCanvas(WidgetTester tester) async {
  // The draw canvas should not be open initially
  expect(find.byKey(const Key('draw_canvas')), findsNothing);
}
