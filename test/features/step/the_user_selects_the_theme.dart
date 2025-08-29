import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user selects the "<theme>" theme
Future<void> theUserSelectsTheTheme(WidgetTester tester, dynamic theme) async {
  assert(TestWorld.settingsOpen, 'Settings must be open');
  final t = theme.toString();
  TestWorld.selectedTheme = t; // 'light'|'dark'|'system'
  // Persist preference
  TestWorld.prefs['theme'] = t;
  // Immediately apply to UI
  if (t == 'system') {
    TestWorld.currentTheme = TestWorld.systemTheme;
  } else {
    TestWorld.currentTheme = t;
  }
}
