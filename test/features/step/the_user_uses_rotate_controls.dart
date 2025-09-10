import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the user uses rotate controls
Future<void> theUserUsesRotateControls(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final pdfN = container.read(documentRepositoryProvider.notifier);

  if (pdf.selectedPlacementIndex != null) {
    // Rotate the selected placement by 45 degrees
    pdfN.updatePlacementRotation(
      page: pdf.currentPage,
      index: pdf.selectedPlacementIndex!,
      rotationDeg: 45.0,
    );
  }
}
