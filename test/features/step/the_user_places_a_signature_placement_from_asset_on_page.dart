import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: the user places a signature placement from asset <second_asset> on page <second_page>
Future<void> theUserPlacesASignaturePlacementFromAssetOnPage(
  WidgetTester tester,
  String assetName,
  int page,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final library = container.read(signatureLibraryProvider);
  var asset = library.where((a) => a.name == assetName).firstOrNull;
  if (asset == null) {
    // add dummy asset
    final id = container
        .read(signatureLibraryProvider.notifier)
        .add(Uint8List(0), name: assetName);
    final updatedLibrary = container.read(signatureLibraryProvider);
    asset = updatedLibrary.firstWhere(
      (a) => a.id == id,
      orElse:
          () => SignatureAsset(id: id, bytes: Uint8List(0), name: assetName),
    );
  }
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(10, 10, 50, 50),
        asset: asset,
      );
}
