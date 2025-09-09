import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: signature placement occurs on the selected page
Future<void> signaturePlacementOccursOnTheSelectedPage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(pdfProvider);

  // Check that there's at least one placement on the current page
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(placements.isNotEmpty, true);
}
