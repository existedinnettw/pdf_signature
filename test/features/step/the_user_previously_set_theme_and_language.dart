import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user previously set theme {"<theme>"} and language {"<language>"}
Future<void> theUserPreviouslySetThemeAndLanguage(
  WidgetTester tester,
  String themeWrapped,
  String languageWrapped,
) async {
  String unwrap(String s) {
    var r = s.trim();
    if (r.startsWith('{') && r.endsWith('}')) {
      r = r.substring(1, r.length - 1).trim();
    }
    if (r.startsWith("'") && r.endsWith("'")) {
      r = r.substring(1, r.length - 1);
    }
    return r;
  }

  final t = unwrap(themeWrapped);
  final lang = unwrap(languageWrapped);
  // Simulate stored values
  TestWorld.prefs['theme'] = t;
  TestWorld.prefs['language'] = lang;
}
