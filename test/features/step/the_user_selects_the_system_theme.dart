import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user selects the "system" theme
Future<void> theUserSelectsTheSystemTheme(WidgetTester tester) async {
  TestWorld.selectedTheme = 'system';
  TestWorld.prefs['theme'] = 'system';
  TestWorld.currentTheme = TestWorld.systemTheme;
}
