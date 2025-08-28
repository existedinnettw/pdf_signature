import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user cannot edit the document
Future<void> theUserCannotEditTheDocument(WidgetTester tester) async {
  expect(TestWorld.exportInProgress, isTrue);
  // Reset flag to simulate export completion
  TestWorld.exportInProgress = false;
}
