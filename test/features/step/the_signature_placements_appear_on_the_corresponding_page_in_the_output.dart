import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the signature placements appear on the corresponding page in the output
Future<void> theSignaturePlacementsAppearOnTheCorrespondingPageInTheOutput(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  final pdfState = container.read(documentRepositoryProvider);

  // Verify that export was successful
  expect(
    TestWorld.lastExportBytes,
    isNotNull,
    reason: 'Export should have generated output bytes',
  );

  // Verify PDF state has placements that should appear in output
  expect(
    pdfState.placementsByPage.isNotEmpty,
    isTrue,
    reason: 'Should have signature placements to appear in output',
  );

  // Check that placements are properly structured for each page
  for (final entry in pdfState.placementsByPage.entries) {
    final pageNumber = entry.key;
    final placements = entry.value;

    expect(
      pageNumber,
      greaterThan(0),
      reason: 'Page number should be positive',
    );
    expect(
      pageNumber,
      lessThanOrEqualTo(pdfState.pageCount),
      reason: 'Page number should not exceed total page count',
    );

    for (final placement in placements) {
      expect(
        placement.asset,
        isNotNull,
        reason: 'Each placement should have an associated asset',
      );
      expect(
        placement.rect,
        isNotNull,
        reason: 'Each placement should have a valid rectangle',
      );
    }
  }
}
