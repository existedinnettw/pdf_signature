import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user is notified that the export is still in progress
Future<void> theUserIsNotifiedThatTheExportIsStillInProgress(
  WidgetTester tester,
) async {
  expect(TestWorld.exportInProgress, isTrue);
}
