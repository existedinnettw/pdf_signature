import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the user has theme {"dark"} and language {"es"} saved
Future<void> theUserHasThemeAndLanguageSaved(
  WidgetTester tester,
  String param1,
  String param2,
) async {
  // Save provided strings
  TestWorld.prefs['theme'] = param1;
  TestWorld.prefs['language'] = param2;
}
