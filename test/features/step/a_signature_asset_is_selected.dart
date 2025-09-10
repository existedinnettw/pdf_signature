import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a signature asset is selected
Future<void> aSignatureAssetIsSelected(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  var library = container.read(signatureAssetRepositoryProvider);

  // If library is empty, add a dummy asset
  if (library.isEmpty) {
    final asset = SignatureAsset(
      id: 'selected_asset',
      bytes: Uint8List(100),
      name: 'Selected Asset',
    );
    container.read(signatureAssetRepositoryProvider.notifier).state = [asset];
    // Re-read the library
    library = container.read(signatureAssetRepositoryProvider);
  }

  expect(
    library.isNotEmpty,
    true,
    reason: 'Library should have at least one asset',
  );
  // For test purposes, we consider the first asset as selected
}
