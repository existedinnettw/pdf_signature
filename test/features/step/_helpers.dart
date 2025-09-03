import 'package:flutter_riverpod/flutter_riverpod.dart';
import '_world.dart';

ProviderContainer getOrCreateContainer() {
  if (TestWorld.container != null) return TestWorld.container!;
  final container = ProviderContainer();
  TestWorld.container = container;
  return container;
}
