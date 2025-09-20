import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a document is open and contains at least one signature placement
Future<void> aDocumentIsOpenAndContainsAtLeastOneSignaturePlacement(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(documentRepositoryProvider.notifier).openPicked(pageCount: 5);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: SignatureAsset(
          sigImage: img.Image(width: 1, height: 1),
          name: 'sig.png',
        ),
      );
}
