import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: the user drags it on the page of the document to place signature placements in multiple locations in the document
Future<void>
theUserDragsItOnThePageOfTheDocumentToPlaceSignaturePlacementsInMultipleLocationsInTheDocument(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final lib = container.read(signatureLibraryProvider);
  final asset =
      lib.isNotEmpty
          ? lib.first
          : SignatureAsset(
            id: 'shared.png',
            bytes: Uint8List(0),
            name: 'shared.png',
          );

  // Ensure PDF is open
  if (!container.read(pdfProvider).loaded) {
    container
        .read(pdfProvider.notifier)
        .openPicked(path: 'mock.pdf', pageCount: 5);
  }

  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: asset,
      );
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 2,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        asset: asset,
      );
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 3,
        rect: Rect.fromLTWH(30, 30, 100, 50),
        asset: asset,
      );
}
