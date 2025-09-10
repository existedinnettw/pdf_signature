import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: identical signature placements appear in each location
Future<void> identicalSignaturePlacementsAppearInEachLocation(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final pdf = container.read(documentRepositoryProvider);
  final allPlacements =
      pdf.placementsByPage.values.expand((list) => list).toList();
  final assetIds = allPlacements.map((p) => p.asset.id).toSet();
  expect(assetIds.length, 1); // All the same
}
