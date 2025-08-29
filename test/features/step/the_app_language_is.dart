import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app language is {"<language>"}
Future<void> theAppLanguageIs(
  WidgetTester tester,
  String param1,
  dynamic language,
) async {
  final lang = language.toString();
  expect(param1, '{${lang}}');
  expect(TestWorld.currentLanguage, lang);
}
