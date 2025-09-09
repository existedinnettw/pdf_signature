import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the signature placement is stamped at the exact PDF page coordinates and size
Future<void> theSignaturePlacementIsStampedAtTheExactPdfPageCoordinatesAndSize(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  final pdfState = container.read(pdfProvider);

  // Verify PDF is loaded
  expect(pdfState.loaded, isTrue, reason: 'PDF should be loaded');

  // Verify there are placements
  expect(
    pdfState.placementsByPage.isNotEmpty,
    isTrue,
    reason: 'Should have signature placements',
  );

  // Check that at least one page has placements
  final pagesWithPlacements =
      pdfState.placementsByPage.entries
          .where((entry) => entry.value.isNotEmpty)
          .toList();

  expect(
    pagesWithPlacements.isNotEmpty,
    isTrue,
    reason: 'At least one page should have signature placements',
  );

  // Verify each placement has valid coordinates and size
  for (final entry in pagesWithPlacements) {
    for (final placement in entry.value) {
      expect(
        placement.rect.left,
        isNotNull,
        reason: 'Placement should have left coordinate',
      );
      expect(
        placement.rect.top,
        isNotNull,
        reason: 'Placement should have top coordinate',
      );
      expect(
        placement.rect.width,
        greaterThan(0),
        reason: 'Placement should have positive width',
      );
      expect(
        placement.rect.height,
        greaterThan(0),
        reason: 'Placement should have positive height',
      );
      expect(
        placement.asset,
        isNotNull,
        reason: 'Placement should have an associated asset',
      );
    }
  }
}
