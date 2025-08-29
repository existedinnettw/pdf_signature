import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app UI theme is {"<theme>"}
Future<void> theAppUiThemeIs(
  WidgetTester tester,
  String param1,
  dynamic theme,
) async {
  final t = theme.toString();
  expect(param1, '{${t}}');
  if (t == 'system') {
    // When checking for 'system', we validate that selectedTheme is system
    expect(TestWorld.selectedTheme, 'system');
  } else {
    expect(TestWorld.currentTheme, t);
  }
}
