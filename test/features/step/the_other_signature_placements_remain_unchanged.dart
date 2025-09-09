import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the other signature placements remain unchanged
Future<void> theOtherSignaturePlacementsRemainUnchanged(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final pdf = container.read(pdfProvider);
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(placements.length, 2); // Should have 2 remaining after deleting 1
}
