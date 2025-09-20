import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
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
        .openPicked(pageCount: 5);
  }

  // Get or create an asset
  var library = container.read(signatureAssetRepositoryProvider);
  SignatureAsset asset;
  if (library.isNotEmpty) {
    asset = library.first;
  } else {
    container
        .read(signatureAssetRepositoryProvider.notifier)
        .addImage(img.Image(width: 1, height: 1), name: 'placement.png');
    asset = container
        .read(signatureAssetRepositoryProvider)
        .firstWhere((a) => a.name == 'placement.png');
  }

  // create a signature card
  final temp_card = SignatureCard(asset: asset, rotationDeg: 0);
  container
      .read(signatureCardRepositoryProvider.notifier)
      .addWithAsset(temp_card.asset, temp_card.rotationDeg);
  // drag and drop (DragTarget<SignatureCard>, `onAccept`) it on document page
  final drop_card = temp_card;

  // Place it on the current page
  final currentPage = container.read(pdfViewModelProvider).currentPage;
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: currentPage,
        rect: const Rect.fromLTWH(100, 100, 100, 50),
        asset: drop_card.asset,
        rotationDeg: drop_card.rotationDeg,
        graphicAdjust: drop_card.graphicAdjust,
      );
}
