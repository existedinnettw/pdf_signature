import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a signature asset is created
Future<void> aSignatureAssetIsCreated(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  // Ensure PDF is open
  if (!container.read(pdfProvider).loaded) {
    container
        .read(pdfProvider.notifier)
        .openPicked(path: 'mock.pdf', pageCount: 5);
  }

  // Create a dummy signature asset
  final asset = SignatureAsset(
    id: 'test_asset',
    bytes: Uint8List(100),
    name: 'Test Asset',
  );
  container.read(signatureLibraryProvider.notifier).state = [asset];

  // Place it on the current page
  final pdf = container.read(pdfProvider);
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: pdf.currentPage,
        rect: Rect.fromLTWH(50, 50, 100, 50),
        asset: asset,
      );
}
