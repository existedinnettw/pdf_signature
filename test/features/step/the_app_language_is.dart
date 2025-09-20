import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app language is {"<language>"}
Future<void> theAppLanguageIs(
  WidgetTester tester,
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

  final lang = unwrap(languageWrapped);
  expect(TestWorld.currentLanguage, lang);
}
