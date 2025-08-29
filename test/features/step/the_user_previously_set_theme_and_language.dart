import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user previously set theme {"<theme>"} and language {"<language>"}
Future<void> theUserPreviouslySetThemeAndLanguage(
  WidgetTester tester,
  String themeWrapped,
  String languageWrapped,
) async {
  String unwrap(String s) =>
      s.startsWith('{') && s.endsWith('}') ? s.substring(1, s.length - 1) : s;
  final t = unwrap(themeWrapped);
  final lang = unwrap(languageWrapped);
  // Simulate stored values
  TestWorld.prefs['theme'] = t;
  TestWorld.prefs['language'] = lang;
}
