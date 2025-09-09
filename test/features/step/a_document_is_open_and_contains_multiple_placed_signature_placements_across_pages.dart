import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a document is open and contains multiple placed signature placements across pages
Future<void>
aDocumentIsOpenAndContainsMultiplePlacedSignaturePlacementsAcrossPages(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'multi.pdf', pageCount: 5);
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: SignatureAsset(id: 'sig1.png', bytes: Uint8List(0)),
      );
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 2,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        asset: SignatureAsset(id: 'sig2.png', bytes: Uint8List(0)),
      );
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 3,
        rect: Rect.fromLTWH(30, 30, 100, 50),
        asset: SignatureAsset(id: 'sig3.png', bytes: Uint8List(0)),
      );
}
