import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the OS appearance switches to dark mode
Future<void> theOsAppearanceSwitchesToDarkMode(WidgetTester tester) async {
  TestWorld.systemTheme = 'dark';
}
