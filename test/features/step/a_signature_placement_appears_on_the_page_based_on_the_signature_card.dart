import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: a signature placement appears on the page based on the signature card
Future<void> aSignaturePlacementAppearsOnThePageBasedOnTheSignatureCard(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final pdf = container.read(documentRepositoryProvider);
  final page = container.read(pdfViewModelProvider);
  final placements = pdf.placementsByPage[page] ?? const [];
  expect(
    placements.isNotEmpty,
    true,
    reason: 'A signature placement should appear on the page',
  );
}
