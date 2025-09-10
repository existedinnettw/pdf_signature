import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the signature placement rotates around its center in real time
Future<void> theSignaturePlacementRotatesAroundItsCenterInRealTime(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);

  if (pdf.selectedPlacementIndex != null) {
    final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
    if (pdf.selectedPlacementIndex! < placements.length) {
      final placement = placements[pdf.selectedPlacementIndex!];
      expect(placement.rotationDeg, 45.0);
    }
  }
}
