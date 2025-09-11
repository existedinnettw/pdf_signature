import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the user chooses undo
Future<void> theUserChoosesUndo(WidgetTester tester) async {
  // Tap the undo button
  await tester.tap(find.byKey(const Key('btn_canvas_undo')));
  await tester.pumpAndSettle();
}
