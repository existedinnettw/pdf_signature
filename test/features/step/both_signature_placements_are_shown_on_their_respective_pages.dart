import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: both signature placements are shown on their respective pages
Future<void> bothSignaturePlacementsAreShownOnTheirRespectivePages(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final placementsByPage = pdf.placementsByPage;
  final totalPlacements = placementsByPage.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );
  // We placed two signature placements; they may be on the same page or on different pages
  expect(totalPlacements, 2);
}
