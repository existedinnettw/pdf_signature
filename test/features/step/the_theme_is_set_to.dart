import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the theme is set to {"system"}
Future<void> theThemeIsSetTo(WidgetTester tester, String param1) async {
  expect(TestWorld.prefs['theme'], param1);
  if (param1 == 'system') {
    expect(TestWorld.selectedTheme, 'system');
  }
}
