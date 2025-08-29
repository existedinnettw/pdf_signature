import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the language is set to the device locale
Future<void> theLanguageIsSetToTheDeviceLocale(WidgetTester tester) async {
  expect(TestWorld.prefs['language'], TestWorld.deviceLocale);
  expect(TestWorld.currentLanguage, TestWorld.deviceLocale);
}
