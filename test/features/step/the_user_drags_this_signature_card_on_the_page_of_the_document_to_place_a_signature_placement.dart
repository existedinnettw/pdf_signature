import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: the user drags this signature card on the page of the document to place a signature placement
Future<void>
theUserDragsThisSignatureCardOnThePageOfTheDocumentToPlaceASignaturePlacement(
  WidgetTester tester,
) async {
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
    final id = container
        .read(signatureAssetRepositoryProvider.notifier)
        .add(bytes, name: 'placement.png');
    asset = container
        .read(signatureAssetRepositoryProvider)
        .firstWhere((a) => a.id == id);
  }

  // Place it on the current page
  final pdf = container.read(documentRepositoryProvider);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: pdf.currentPage,
        rect: Rect.fromLTWH(100, 100, 100, 50),
        asset: asset,
      );
}
