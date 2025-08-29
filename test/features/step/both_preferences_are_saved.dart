import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: both preferences are saved
Future<void> bothPreferencesAreSaved(WidgetTester tester) async {
  expect(TestWorld.prefs.containsKey('theme'), true);
  expect(TestWorld.prefs.containsKey('language'), true);
}
