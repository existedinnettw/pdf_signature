import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: the user drags it on the page of the document to place signature placements in multiple locations in the document
Future<void>
theUserDragsItOnThePageOfTheDocumentToPlaceSignaturePlacementsInMultipleLocationsInTheDocument(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final lib = container.read(signatureAssetRepositoryProvider);
  final asset =
      lib.isNotEmpty
          ? lib.first
          : SignatureAsset(bytes: Uint8List(0), name: 'shared.png');

  // Ensure PDF is open
  if (!container.read(documentRepositoryProvider).loaded) {
    container
        .read(documentRepositoryProvider.notifier)
        .openPicked(pageCount: 5);
  }

  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: asset,
      );
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 2,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        asset: asset,
      );
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 3,
        rect: Rect.fromLTWH(30, 30, 100, 50),
        asset: asset,
      );
}
