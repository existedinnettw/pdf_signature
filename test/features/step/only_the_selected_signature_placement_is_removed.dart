import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: only the selected signature placement is removed
Future<void> onlyTheSelectedSignaturePlacementIsRemoved(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final page = container.read(pdfViewModelProvider);
  final placements = pdf.placementsByPage[page] ?? const [];
  expect(placements.length, 2); // Started with 3, removed 1, should have 2
}
