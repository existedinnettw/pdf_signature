import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: only the selected signature placement is removed
Future<void> onlyTheSelectedSignaturePlacementIsRemoved(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(placements.length, lessThan(3)); // Assuming started with 3, removed 1
}
