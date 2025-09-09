import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a document is open and contains at least one signature placement
Future<void> aDocumentIsOpenAndContainsAtLeastOneSignaturePlacement(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'test.pdf', pageCount: 5);
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: 1,
        rect: Rect.fromLTWH(10, 10, 100, 50),
        asset: SignatureAsset(id: 'sig.png', bytes: Uint8List(0)),
      );
}
