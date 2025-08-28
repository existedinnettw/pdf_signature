import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user starts exporting the document
Future<void> theUserStartsExportingTheDocument(WidgetTester tester) async {
  TestWorld.exportInProgress = true;
}
