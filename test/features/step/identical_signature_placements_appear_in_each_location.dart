import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: identical signature placements appear in each location
Future<void> identicalSignaturePlacementsAppearInEachLocation(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final pdf = container.read(pdfProvider);
  final allPlacements =
      pdf.placementsByPage.values.expand((list) => list).toList();
  final assetIds = allPlacements.map((p) => p.asset.id).toSet();
  expect(assetIds.length, 1); // All the same
}
