import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user places two signature placements on the same page
Future<void> theUserPlacesTwoSignaturePlacementsOnTheSamePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // pdfViewModelProvider returns 1-based current page
  final page = container.read(pdfViewModelProvider).currentPage;
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'sig1.png',
        ),
      );
  await tester.pumpAndSettle();
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(120, 10, 100, 50),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'sig2.png',
        ),
      );
  await tester.pumpAndSettle();
}
