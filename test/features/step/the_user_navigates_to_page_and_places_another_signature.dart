import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user navigates to page {3} and places another signature
Future<void> theUserNavigatesToPageAndPlacesAnotherSignature(
  WidgetTester tester,
  num page,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Ensure doc open
  final pdf = container.read(pdfProvider);
  if (!pdf.loaded) {
    container
        .read(pdfProvider.notifier)
        .openPicked(path: 'mock.pdf', pageCount: 6);
  }
  container.read(pdfProvider.notifier).jumpTo(page.toInt());
  // Ensure an image is loaded
  if (container.read(signatureProvider).imageBytes == null) {
    container
        .read(signatureProvider.notifier)
        .setImageBytes(Uint8List.fromList([1, 2, 3]));
  }
  container.read(signatureProvider.notifier).placeDefaultRect();
  final Rect r = container.read(signatureProvider).rect!;
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: page.toInt(), rect: r, image: 'default.png');
}
