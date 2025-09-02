import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user places a signature on the page
Future<void> theUserPlacesASignatureOnThePage(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(pdfProvider);
  if (!pdf.loaded) {
    container
        .read(pdfProvider.notifier)
        .openPicked(path: 'mock.pdf', pageCount: 1);
    container.read(pdfProvider.notifier).setSignedPage(1);
  }
  // Ensure image bytes
  if (container.read(signatureProvider).imageBytes == null) {
    final name = TestWorld.currentImageName ?? 'alice.png';
    Uint8List bytes =
        name == 'bob.png'
            ? Uint8List.fromList([4, 5, 6])
            : Uint8List.fromList([1, 2, 3]);
    container.read(signatureProvider.notifier).setImageBytes(bytes);
  }
  container.read(signatureProvider.notifier).placeDefaultRect();
  final Rect r = container.read(signatureProvider).rect!;
  final int page = container.read(pdfProvider).signedPage ?? 1;
  final imgName = TestWorld.currentImageName ?? 'alice.png';
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: page, rect: r, image: imgName);
  // Select the just placed signature (last index)
  final list = container.read(pdfProvider).placementsByPage[page] ?? const [];
  container
      .read(pdfProvider.notifier)
      .selectPlacement(list.isEmpty ? null : (list.length - 1));
}
