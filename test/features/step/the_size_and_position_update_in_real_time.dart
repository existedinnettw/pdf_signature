import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the size and position update in real time
Future<void> theSizeAndPositionUpdateInRealTime(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);

  if (pdf.selectedPlacementIndex != null) {
    final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
    if (pdf.selectedPlacementIndex! < placements.length) {
      final currentRect = placements[pdf.selectedPlacementIndex!].rect;
      expect(currentRect.center, isNot(TestWorld.prevCenter));
    }
  }
}
