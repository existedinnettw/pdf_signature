import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user uses rotate controls
Future<void> theUserUsesRotateControls(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);
  final pdfN = container.read(pdfProvider.notifier);

  if (pdf.selectedPlacementIndex != null) {
    // Rotate the selected placement by 45 degrees
    pdfN.updatePlacementRotation(
      page: pdf.currentPage,
      index: pdf.selectedPlacementIndex!,
      rotationDeg: 45.0,
    );
  }
}
