import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: the user places a signature placement from asset <secondAsset> on page <secondPage>
Future<void> theUserPlacesASignaturePlacementFromAssetOnPage(
  WidgetTester tester,
  String assetName,
  int page,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final library = container.read(signatureAssetRepositoryProvider);
  var asset = library.where((a) => a.name == assetName).firstOrNull;
  if (asset == null) {
    // add dummy asset
    container
        .read(signatureAssetRepositoryProvider.notifier)
        .addImage(img.Image(width: 1, height: 1), name: assetName);
    final updatedLibrary = container.read(signatureAssetRepositoryProvider);
    asset = updatedLibrary.firstWhere((a) => a.name == assetName);
  }
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(10, 10, 50, 50),
        asset: asset,
      );
  await tester.pumpAndSettle();
}
