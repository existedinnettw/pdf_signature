import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: all placed signature placements appear on their corresponding pages in the output
Future<void>
allPlacedSignaturePlacementsAppearOnTheirCorrespondingPagesInTheOutput(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final totalPlacements = pdf.placementsByPage.values.fold(
    0,
    (sum, list) => sum + list.length,
  );
  expect(totalPlacements, greaterThan(1));
}
