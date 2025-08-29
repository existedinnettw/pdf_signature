import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the preference {language} is saved as {"<language>"}
Future<void> thePreferenceIsSavedAs(
  WidgetTester tester,
  dynamic keyToken,
  String valueWrapped,
) async {
  String unwrap(String s) =>
      s.startsWith('{') && s.endsWith('}') ? s.substring(1, s.length - 1) : s;
  final key = keyToken.toString();
  final expected = unwrap(valueWrapped);
  expect(TestWorld.prefs[key], expected);
}
