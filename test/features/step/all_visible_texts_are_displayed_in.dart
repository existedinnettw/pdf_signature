import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: all visible texts are displayed in "<language>"
Future<void> allVisibleTextsAreDisplayedIn(
  WidgetTester tester,
  dynamic language,
) async {
  expect(TestWorld.currentLanguage, language.toString());
}
