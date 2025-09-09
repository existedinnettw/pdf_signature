import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_library_repository.dart';
import '_world.dart';

/// Usage: the user chooses a signature asset to created a signature card
Future<void> theUserChoosesASignatureAssetToCreatedASignatureCard(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
  container
      .read(signatureLibraryProvider.notifier)
      .add(bytes, name: 'card.png');
}
