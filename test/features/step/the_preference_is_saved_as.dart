import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the preference {language} is saved as {"<language>"}
Future<void> thePreferenceIsSavedAs(
  WidgetTester tester,
  dynamic param1,
  String param2,
  dynamic _value,
) async {
  final key = param1.toString();
  final expectedTokenWrapped = param2; // like "{light}"
  final expectedValue = _value.toString();
  // Check token string matches braces-syntax just for parity
  expect(expectedTokenWrapped, '{${expectedValue}}');
  expect(TestWorld.prefs[key], expectedValue);
}
