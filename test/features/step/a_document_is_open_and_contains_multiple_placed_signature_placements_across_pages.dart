import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a document is open and contains multiple placed signature placements across pages
Future<void>
aDocumentIsOpenAndContainsMultiplePlacedSignaturePlacementsAcrossPages(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(documentRepositoryProvider.notifier).openPickedWithPageCount(pageCount: 5);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(0.1, 0.1, 0.2, 0.1),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'sig1.png',
        ),
      );
  await tester.pumpAndSettle();
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 2,
        rect: Rect.fromLTWH(0.2, 0.2, 0.2, 0.1),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'sig2.png',
        ),
      );
  await tester.pumpAndSettle();
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 3,
        rect: Rect.fromLTWH(0.3, 0.3, 0.2, 0.1),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'sig3.png',
        ),
      );
  await tester.pumpAndSettle();
}
