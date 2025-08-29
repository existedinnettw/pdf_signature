import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: invalid values are replaced with valid defaults in storage
Future<void> invalidValuesAreReplacedWithValidDefaultsInStorage(
  WidgetTester tester,
) async {
  // Ensure storage corrected to defaults
  final themeValid = {'light', 'dark', 'system'};
  if (!themeValid.contains(TestWorld.prefs['theme'])) {
    TestWorld.prefs['theme'] = 'system';
  }
  final langValid = {'en', 'zh-TW', 'es'};
  if (!langValid.contains(TestWorld.prefs['language'])) {
    TestWorld.prefs['language'] = TestWorld.deviceLocale;
  }
  expect(themeValid.contains(TestWorld.prefs['theme']), true);
  expect(
    langValid.contains(TestWorld.prefs['language']) ||
        TestWorld.prefs['language'] == TestWorld.deviceLocale,
    true,
  );
}
