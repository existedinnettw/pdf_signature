import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: three signature placements are placed on the current page
Future<void> threeSignaturePlacementsArePlacedOnTheCurrentPage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Reset repositories to a known initial state
  container.read(signatureAssetRepositoryProvider.notifier).state = [];
  container.read(documentRepositoryProvider.notifier).state =
      Document.initial();
  container.read(signatureCardRepositoryProvider.notifier).state = [
    SignatureCard.initial(),
  ];
  container.read(documentRepositoryProvider.notifier).openPicked(pageCount: 5);
  final pdfN = container.read(documentRepositoryProvider.notifier);
  final page = container.read(pdfViewModelProvider).currentPage;
  pdfN.addPlacement(
    page: page,
    rect: Rect.fromLTWH(10, 10, 50, 50),
    asset: SignatureAsset(bytes: Uint8List(0), name: 'test1'),
  );
  await tester.pumpAndSettle();
  pdfN.addPlacement(
    page: page,
    rect: Rect.fromLTWH(70, 10, 50, 50),
    asset: SignatureAsset(bytes: Uint8List(0), name: 'test2'),
  );
  await tester.pumpAndSettle();
  pdfN.addPlacement(
    page: page,
    rect: Rect.fromLTWH(130, 10, 50, 50),
    asset: SignatureAsset(bytes: Uint8List(0), name: 'test3'),
  );
  await tester.pumpAndSettle();
}
