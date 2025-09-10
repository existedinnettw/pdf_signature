import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: three signature placements are placed on the current page
Future<void> threeSignaturePlacementsArePlacedOnTheCurrentPage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(signatureAssetRepositoryProvider.notifier).state = [];
  container.read(documentRepositoryProvider.notifier).state =
      Document.initial();
  container.read(signatureCardProvider.notifier).state =
      SignatureCard.initial();
  container.read(currentRectProvider.notifier).state = null;
  container.read(editingEnabledProvider.notifier).state = false;
  container.read(aspectLockedProvider.notifier).state = false;
  container
      .read(documentRepositoryProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 5);
  final pdfN = container.read(documentRepositoryProvider.notifier);
  final pdf = container.read(documentRepositoryProvider);
  final page = pdf.currentPage;
  pdfN.addPlacement(
    page: page,
    rect: Rect.fromLTWH(10, 10, 50, 50),
    asset: SignatureAsset(id: 'test1', bytes: Uint8List(0), name: 'test1'),
  );
  pdfN.addPlacement(
    page: page,
    rect: Rect.fromLTWH(70, 10, 50, 50),
    asset: SignatureAsset(id: 'test2', bytes: Uint8List(0), name: 'test2'),
  );
  pdfN.addPlacement(
    page: page,
    rect: Rect.fromLTWH(130, 10, 50, 50),
    asset: SignatureAsset(id: 'test3', bytes: Uint8List(0), name: 'test3'),
  );
}
