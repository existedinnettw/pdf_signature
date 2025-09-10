import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: the user places a signature placement from asset <second_asset> on page <second_page>
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
        .add(Uint8List(100), name: assetName);
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
}
