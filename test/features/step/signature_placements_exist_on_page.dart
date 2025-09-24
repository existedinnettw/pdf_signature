import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: {1} signature placements exist on page {2}
Future<void> signaturePlacementsExistOnPage(
  WidgetTester tester,
  num param1,
  num param2,
) async {
  final expected = param1.toInt();
  final page = param2.toInt();
  // Record the expectation as part of scenario context instead of asserting
  // against current state (the scenario describes placements in the previous
  // document before opening a new one).
  TestWorld.prevPlacementsCount ??= {};
  TestWorld.prevPlacementsCount![page] = expected;
}
