import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: resize to fit within bounding box
Future<void> resizeToFitWithinBoundingBox(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);

  final placements = pdf.placementsByPage[] ?? [];
  for (final placement in placements) {
    // Assume page size is 800x600 for testing
    const pageWidth = 800.0;
    const pageHeight = 600.0;

    expect(placement.rect.left, greaterThanOrEqualTo(0));
    expect(placement.rect.top, greaterThanOrEqualTo(0));
    expect(placement.rect.right, lessThanOrEqualTo(pageWidth));
    expect(placement.rect.bottom, lessThanOrEqualTo(pageHeight));
  }
}
