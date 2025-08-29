import 'package:flutter_test/flutter_test.dart';

/// Usage: pdf marked for signing is {false}
Future<void> pdfMarkedForSigningIs(WidgetTester tester, bool expected) async {
  // Feature removed; assert expectation is false for backward compatibility
  expect(expected, false);
}
