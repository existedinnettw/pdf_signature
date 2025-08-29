import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app language is {"<language>"}
Future<void> theAppLanguageIs(
  WidgetTester tester,
  String languageWrapped,
) async {
  String unwrap(String s) =>
      s.startsWith('{') && s.endsWith('}') ? s.substring(1, s.length - 1) : s;
  final lang = unwrap(languageWrapped);
  expect(TestWorld.currentLanguage, lang);
}
