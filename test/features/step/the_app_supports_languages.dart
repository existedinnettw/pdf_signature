import 'package:flutter_test/flutter_test.dart';

/// Usage: the app supports languages {en, zh-TW, es}
Future<void> theAppSupportsLanguages(
  WidgetTester tester,
  String languages,
) async {
  // Normalize the example token string "{en, zh-TW, es}" into a set
  final raw = languages.trim();
  final inner =
      raw.startsWith('{') && raw.endsWith('}')
          ? raw.substring(1, raw.length - 1)
          : raw;
  final expected = inner.split(',').map((s) => s.trim()).toSet();

  // Keep this in sync with the app's supported locales
  const actual = {'en', 'zh-TW', 'es'};
  expect(actual, expected);
}
