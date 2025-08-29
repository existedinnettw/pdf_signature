import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app UI theme is {"<theme>"}
Future<void> theAppUiThemeIs(WidgetTester tester, String themeWrapped) async {
  String unwrap(String s) =>
      s.startsWith('{') && s.endsWith('}') ? s.substring(1, s.length - 1) : s;
  final t = unwrap(themeWrapped);
  if (t == 'system') {
    // When checking for 'system', we validate that selectedTheme is system
    expect(TestWorld.selectedTheme, 'system');
  } else {
    expect(TestWorld.currentTheme, t);
  }
}
