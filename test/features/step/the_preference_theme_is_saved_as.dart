import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the preference 'theme' is saved as {"<theme>"}
Future<void> thePreferenceThemeIsSavedAs(
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
  expect(TestWorld.prefs['theme'], expected);
}
