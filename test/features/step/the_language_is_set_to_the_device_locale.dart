import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the language is set to the device locale
Future<void> theLanguageIsSetToTheDeviceLocale(WidgetTester tester) async {
  // On first launch there may be no stored preference yet; only the
  // effective current language must match the device locale.
  if (TestWorld.prefs['language'] != null) {
    expect(TestWorld.prefs['language'], TestWorld.deviceLocale);
  }
  expect(TestWorld.currentLanguage, TestWorld.deviceLocale);
}
