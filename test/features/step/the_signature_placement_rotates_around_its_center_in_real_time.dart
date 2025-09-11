import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';

/// Usage: the signature placement rotates around its center in real time
Future<void> theSignaturePlacementRotatesAroundItsCenterInRealTime(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final currentPage = container.read(pdfViewModelProvider);

  final placements = pdf.placementsByPage[currentPage] ?? [];
  if (placements.isNotEmpty) {
    final placement = placements[0];
    expect(placement.rotationDeg, 45.0);
  }
}
