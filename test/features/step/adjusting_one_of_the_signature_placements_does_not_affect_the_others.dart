import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: adjusting one of the signature placements does not affect the others
Future<void> adjustingOneOfTheSignaturePlacementsDoesNotAffectTheOthers(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final pdf = container.read(documentRepositoryProvider);
  final placements =
      pdf.placementsByPage.values.expand((list) => list).toList();

  // All placements should have the same asset (reusing the same asset)
  final assets = placements.map((p) => p.asset).toSet();
  expect(assets.length, 1);

  // All should have default rotation (0.0) since none were adjusted
  final rotations = placements.map((p) => p.rotationDeg).toSet();
  expect(rotations.length, 1);
  expect(rotations.first, 0.0);
}
