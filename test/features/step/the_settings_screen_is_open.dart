import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the settings screen is open
Future<void> theSettingsScreenIsOpen(WidgetTester tester) async {
  // Simulate navigating to settings; no real UI dependency.
  TestWorld.settingsOpen = true;
}
