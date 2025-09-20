import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: the user places a signature placement from asset <secondAsset> on page <secondPage>
/// Note: Parameters are optional to accommodate generated tests that omit them; defaults will be used.
Future<void> theUserPlacesASignaturePlacementFromAssetOnPage(
  WidgetTester tester, [
  dynamic assetName = 'alice.png',
  dynamic page = 1,
]) async {
  // Normalize inputs from generated feature examples
  String normalizeName(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.length >= 2 &&
        ((s.startsWith("'") && s.endsWith("'")) ||
            (s.startsWith('"') && s.endsWith('"')))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  int normalizePage(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 1;
  }

  final assetNameStr = normalizeName(assetName);
  final pageNum = normalizePage(page);
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final library = container.read(signatureAssetRepositoryProvider);
  var asset = library.where((a) => a.name == assetNameStr).firstOrNull;
  if (asset == null) {
    // add dummy asset
    container
        .read(signatureAssetRepositoryProvider.notifier)
        .addImage(img.Image(width: 1, height: 1), name: assetNameStr);
    final updatedLibrary = container.read(signatureAssetRepositoryProvider);
    asset = updatedLibrary.firstWhere((a) => a.name == assetNameStr);
  }
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: pageNum,
        rect: Rect.fromLTWH(10, 10, 50, 50),
        asset: asset,
      );
  await tester.pumpAndSettle();
}
