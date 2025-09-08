import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user saves/exports the document
Future<void> theUserSavesexportsTheDocument(WidgetTester tester) async {
  // Logic-only: simulate a successful export without invoking IO or printing raster
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  // Ensure state looks exportable
  final pdf = container.read(pdfProvider);
  final sig = container.read(signatureProvider);
  expect(pdf.loaded, isTrue, reason: 'PDF must be loaded before export');
  expect(pdf.signedPage, isNotNull, reason: 'A signed page must be selected');
  expect(sig.rect, isNotNull, reason: 'Signature rect must exist');
  expect(sig.imageBytes, isNotNull, reason: 'Signature image must exist');

  // Simulate output
  TestWorld.lastExportBytes =
      TestWorld.lastExportBytes ?? Uint8List.fromList([1, 2, 3]);
}
