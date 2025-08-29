import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: stored preferences contain theme {"sepia"} and language {"xx"}
Future<void> storedPreferencesContainThemeAndLanguage(
  WidgetTester tester,
  String param1,
  String param2,
) async {
  // Store invalid values as given
  TestWorld.prefs['theme'] = param1;
  TestWorld.prefs['language'] = param2;
}
