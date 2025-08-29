import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user previously set theme {"<theme>"} and language {"<language>"}
Future<void> theUserPreviouslySetThemeAndLanguage(
  WidgetTester tester,
  String param1,
  String param2,
  dynamic theme,
  dynamic language,
) async {
  final t = theme.toString();
  final lang = language.toString();
  expect(param1, '{${t}}');
  expect(param2, '{${lang}}');
  // Simulate stored values
  TestWorld.prefs['theme'] = t;
  TestWorld.prefs['language'] = lang;
}
