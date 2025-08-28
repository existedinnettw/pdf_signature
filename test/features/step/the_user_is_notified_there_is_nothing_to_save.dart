import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user is notified there is nothing to save
Future<void> theUserIsNotifiedThereIsNothingToSave(WidgetTester tester) async {
  expect(TestWorld.nothingToSaveAttempt, isTrue);
}
