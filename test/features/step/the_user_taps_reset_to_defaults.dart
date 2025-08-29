import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user taps "Reset to defaults"
Future<void> theUserTapsResetToDefaults(WidgetTester tester) async {
  // Reset to defaults: theme system, language device locale
  TestWorld.prefs['theme'] = 'system';
  TestWorld.prefs['language'] = TestWorld.deviceLocale;
  TestWorld.selectedTheme = 'system';
  TestWorld.currentTheme = TestWorld.systemTheme;
  TestWorld.currentLanguage = TestWorld.deviceLocale;
}
