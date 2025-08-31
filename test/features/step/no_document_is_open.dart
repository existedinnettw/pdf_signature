import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '_world.dart';

/// Usage: no document is open
Future<void> noDocumentIsOpen(WidgetTester tester) async {
  // Reset to a fresh container with initial provider state
  TestWorld.container?.dispose();
  TestWorld.container = ProviderContainer();
}
