import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the preference 'language' is saved as {"<language>"}
Future<void> thePreferenceLanguageIsSavedAs(
  WidgetTester tester, [
  dynamic valueWrapped,
]) async {
  String unwrap(String s) {
    var out = s.trim();
    if (out.startsWith('{') && out.endsWith('}')) {
      out = out.substring(1, out.length - 1);
    }
    if ((out.startsWith("'") && out.endsWith("'")) ||
        (out.startsWith('"') && out.endsWith('"'))) {
      out = out.substring(1, out.length - 1);
    }
    return out;
  }

  final expected = unwrap((valueWrapped ?? '').toString());
  expect(TestWorld.prefs['language'], expected);
}
