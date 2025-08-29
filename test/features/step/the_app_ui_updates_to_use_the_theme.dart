import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app UI updates to use the "<theme>" theme
Future<void> theAppUiUpdatesToUseTheTheme(
  WidgetTester tester,
  dynamic theme,
) async {
  final expected = theme.toString();
  final actual = TestWorld.currentTheme;
  if (expected == 'system') {
    expect(actual, TestWorld.systemTheme);
  } else {
    expect(actual, expected);
  }
}
