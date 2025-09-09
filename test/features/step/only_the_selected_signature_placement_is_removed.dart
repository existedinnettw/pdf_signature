import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: only the selected signature placement is removed
Future<void> onlyTheSelectedSignaturePlacementIsRemoved(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(placements.length, 2); // Started with 3, removed 1, should have 2
}
