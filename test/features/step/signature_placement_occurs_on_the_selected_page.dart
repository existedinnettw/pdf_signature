import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: signature placement occurs on the selected page
Future<void> signaturePlacementOccursOnTheSelectedPage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);

  // Check that there's at least one placement on the current page
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(placements.isNotEmpty, true);
}
