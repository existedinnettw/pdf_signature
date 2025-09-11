import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a signature asset is placed on the page
Future<void> aSignatureAssetIsPlacedOnThePage(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  // Ensure PDF is open
  if (!container.read(documentRepositoryProvider).loaded) {
    container
        .read(documentRepositoryProvider.notifier)
        .openPicked(path: 'mock.pdf', pageCount: 5);
  }

  // Get or create an asset
  var library = container.read(signatureAssetRepositoryProvider);
  SignatureAsset asset;
  if (library.isNotEmpty) {
    asset = library.first;
  } else {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    container
        .read(signatureAssetRepositoryProvider.notifier)
        .add(bytes, name: 'test.png');
    asset = container
        .read(signatureAssetRepositoryProvider)
        .firstWhere((a) => a.name == 'test.png');
  }

  // Place it on the current page
  final pdf = container.read(documentRepositoryProvider);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: ,
        rect: Rect.fromLTWH(50, 50, 100, 50),
        asset: asset,
      );
}
