import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user uses rotate controls
Future<void> theUserUsesRotateControls(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdfN = container.read(documentRepositoryProvider.notifier);
  final currentPage = container.read(pdfViewModelProvider).currentPage;
  final placements = pdfN.placementsOn(currentPage);
  if (placements.isNotEmpty) {
    pdfN.updatePlacementRotation(
      page: currentPage,
      index: 0,
      rotationDeg: 45.0,
    );
  }
}
