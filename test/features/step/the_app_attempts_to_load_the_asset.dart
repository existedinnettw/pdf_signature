import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import '_world.dart';

/// Usage: the app attempts to load the asset
Future<void> theAppAttemptsToLoadTheAsset(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Simulate attempting to load an asset - for now just ensure library is accessible
  final library = container.read(signatureLibraryProvider);
  expect(library, isNotNull);
}
