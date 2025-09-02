import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user places a signature from picture <second_image> on page <second_page>
Future<void> theUserPlacesASignatureFromPictureOnPage(
  WidgetTester tester, [
  dynamic imageName,
  dynamic pageNumber,
]) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Ensure a document is open
  final pdf = container.read(pdfProvider);
  if (!pdf.loaded) {
    container
        .read(pdfProvider.notifier)
        .openPicked(path: 'mock.pdf', pageCount: 6);
  }
  // Load image bytes based on provided name
  if (imageName == null) {
    // Alternate between alice/bob for the first two calls to match Examples
    final idx = TestWorld.placeFromPictureCallCount++;
    imageName = (idx % 2 == 0) ? 'alice.png' : 'bob.png';
  }
  final String name =
      imageName is String
          ? imageName
          : (imageName?.toString() ?? 'default.png');
  Uint8List bytes;
  switch (name) {
    case 'alice.png':
      bytes = Uint8List.fromList([1, 2, 3]);
      break;
    case 'bob.png':
      bytes = Uint8List.fromList([4, 5, 6]);
      break;
    default:
      bytes = Uint8List.fromList([7, 8, 9]);
  }
  container.read(signatureProvider.notifier).setImageBytes(bytes);
  // Place default rect and add placement on target page with image name
  container.read(signatureProvider.notifier).placeDefaultRect();
  final Rect r = container.read(signatureProvider).rect!;
  final int page =
      (pageNumber is num)
          ? pageNumber.toInt()
          : int.tryParse(pageNumber?.toString() ?? '') ??
              // Default pages for the two calls in the scenario: 1 then 3
              ((TestWorld.placeFromPictureCallCount <= 1) ? 1 : 3);
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: page, rect: r, image: name);
}
