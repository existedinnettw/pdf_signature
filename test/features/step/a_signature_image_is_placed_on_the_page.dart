import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: a signature image is placed on the page
Future<void> aSignatureImageIsPlacedOnThePage(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 5);
  container.read(pdfProvider.notifier).setSignedPage(1);
  // Set an image to ensure rect exists
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
}
