import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the language falls back to the device locale
Future<void> theLanguageFallsBackToTheDeviceLocale(WidgetTester tester) async {
  final stored = TestWorld.prefs['language'];
  final valid = {'en', 'zh-TW', 'es'};
  final fallback = valid.contains(stored) ? stored : TestWorld.deviceLocale;
  expect(fallback, TestWorld.deviceLocale);
  TestWorld.currentLanguage = fallback;
}
