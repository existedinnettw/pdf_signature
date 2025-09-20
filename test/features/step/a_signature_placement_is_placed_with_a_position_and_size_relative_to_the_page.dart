import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a signature placement is placed with a position and size relative to the page
Future<void> aSignaturePlacementIsPlacedWithAPositionAndSizeRelativeToThePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  if (!container.read(documentRepositoryProvider).loaded) {
    container
        .read(documentRepositoryProvider.notifier)
        .openPicked(pageCount: 5);
  }
  final currentPage = container.read(pdfViewModelProvider).currentPage;
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: currentPage,
        // Use normalized 0..1 fractions relative to page size as required
        rect: const Rect.fromLTWH(0.2, 0.3, 0.4, 0.2),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'test.png',
        ),
      );
  await tester.pumpAndSettle();
}
