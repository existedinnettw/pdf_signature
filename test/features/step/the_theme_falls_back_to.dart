import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the theme falls back to {"system"}
Future<void> theThemeFallsBackTo(WidgetTester tester, String param1) async {
  // On launch, if invalid theme, fallback to 'system'
  final stored = TestWorld.prefs['theme'];
  final valid = {'light', 'dark', 'system'};
  final fallback = valid.contains(stored) ? stored : 'system';
  expect(fallback, param1);
  // apply
  TestWorld.selectedTheme = fallback;
  TestWorld.currentTheme =
      fallback == 'system' ? TestWorld.systemTheme : fallback;
}
