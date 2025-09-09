import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user deletes one selected signature placement
Future<void> theUserDeletesOneSelectedSignaturePlacement(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(pdfProvider);
  if (pdf.selectedPlacementIndex == null) {
    container.read(pdfProvider.notifier).selectPlacement(0);
  }
  container.read(pdfProvider.notifier).deleteSelectedPlacement();
}
