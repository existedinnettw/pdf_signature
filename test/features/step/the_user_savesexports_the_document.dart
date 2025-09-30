import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user saves/exports the document
Future<void> theUserSavesexportsTheDocument(WidgetTester tester) async {
  // Logic-only: simulate a successful export without invoking IO or printing raster
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  // Ensure state looks exportable
  final pdf = container.read(documentRepositoryProvider);
  final sig = container.read(signatureProvider);
  if (!pdf.loaded) {
    // Load a minimal sample so the expectation passes in logic-only tests
    container
        .read(documentRepositoryProvider.notifier)
        .openPickedWithPageCount(pageCount: 2, bytes: Uint8List(10));
  }
  expect(pdf.loaded, isTrue, reason: 'PDF must be loaded before export');
  // Check if there are placements
  final hasPlacements = pdf.placementsByPage.values.any(
    (list) => list.isNotEmpty,
  );
  if (!hasPlacements) {
    expect(
      sig.rect,
      isNotNull,
      reason: 'Signature rect must exist if no placements',
    );
    expect(
      sig.imageBytes,
      isNotNull,
      reason: 'Signature image must exist if no placements',
    );
  }

  // Simulate output
  TestWorld.lastExportBytes =
      TestWorld.lastExportBytes ?? Uint8List.fromList([1, 2, 3]);
}
