import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the preference {language} is saved as {"<language>"}
Future<void> thePreferenceIsSavedAs(
  WidgetTester tester,
  dynamic keyToken,
  String valueWrapped,
) async {
  String unwrap(String s) {
    var out = s;
    if (out.startsWith('{') && out.endsWith('}')) {
      out = out.substring(1, out.length - 1);
    }
    // Remove surrounding single or double quotes if present
    if ((out.startsWith("'") && out.endsWith("'")) ||
        (out.startsWith('"') && out.endsWith('"'))) {
      out = out.substring(1, out.length - 1);
    }
    return out;
  }

  final key = keyToken.toString();
  final expected = unwrap(valueWrapped);
  expect(TestWorld.prefs[key], expected);
}
