import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user selects a supported language "<language>"
Future<void> theUserSelectsASupportedLanguage(
  WidgetTester tester,
  dynamic language,
) async {
  assert(TestWorld.settingsOpen, 'Settings must be open');
  final lang = language.toString();
  // Pretend it's in the supported list
  TestWorld.currentLanguage = lang;
  TestWorld.prefs['language'] = lang;
}
