import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user types {4} into the Go to input
Future<void> theUserTypesIntoTheGoToInput(
  WidgetTester tester,
  num param1,
) async {
  TestWorld.pendingGoTo = param1.toInt();
}
