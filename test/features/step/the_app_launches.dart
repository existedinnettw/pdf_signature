import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app launches
Future<void> theAppLaunches(WidgetTester tester) async {
  // Read stored preferences and apply
  final theme = TestWorld.prefs['theme'] ?? 'system';
  TestWorld.selectedTheme = theme;
  TestWorld.currentTheme = theme == 'system' ? TestWorld.systemTheme : theme;
  final lang = TestWorld.prefs['language'] ?? TestWorld.deviceLocale;
  TestWorld.currentLanguage = lang;
}
