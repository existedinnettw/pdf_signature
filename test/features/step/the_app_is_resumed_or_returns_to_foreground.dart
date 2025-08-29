import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app is resumed or returns to foreground
Future<void> theAppIsResumedOrReturnsToForeground(WidgetTester tester) async {
  // On resume, if theme is 'system', re-apply based on current OS theme
  if (TestWorld.selectedTheme == 'system') {
    TestWorld.currentTheme = TestWorld.systemTheme;
  }
}
