import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the app UI updates to use the "dark" theme
Future<void> theAppUiUpdatesToUseTheDarkTheme(WidgetTester tester) async {
  expect(TestWorld.currentTheme, 'dark');
}
