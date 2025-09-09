import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import '_world.dart';

/// Usage: the user drags it on the page of the document to place signature placements in multiple locations in the document
Future<void>
theUserDragsItOnThePageOfTheDocumentToPlaceSignaturePlacementsInMultipleLocationsInTheDocument(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final lib = container.read(signatureLibraryProvider);
  final assetId = lib.isNotEmpty ? lib.first.id : 'shared.png';
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        assetId: assetId,
      );
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 2,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        assetId: assetId,
      );
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 3,
        rect: Rect.fromLTWH(30, 30, 100, 50),
        assetId: assetId,
      );
}
