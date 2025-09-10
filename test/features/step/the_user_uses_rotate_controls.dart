import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user uses rotate controls
Future<void> theUserUsesRotateControls(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final pdfN = container.read(documentRepositoryProvider.notifier);

  final placements = pdfN.placementsOn(pdf.currentPage);
  if (placements.isNotEmpty) {
    // Rotate the first placement by 45 degrees
    pdfN.updatePlacementRotation(
      page: pdf.currentPage,
      index: 0,
      rotationDeg: 45.0,
    );
  }
}
