import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '_world.dart';

/// Usage: a new provider container
Future<void> aNewProviderContainer(WidgetTester tester) async {
  // Ensure a fresh world per scenario
  TestWorld.container?.dispose();
  TestWorld.reset();
  TestWorld.container = ProviderContainer();
  addTearDown(() {
    TestWorld.container?.dispose();
    TestWorld.container = null;
  });
}
