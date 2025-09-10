import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the user drags handles to resize and drags to reposition
Future<void> theUserDragsHandlesToResizeAndDragsToReposition(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);
  final pdfN = container.read(documentRepositoryProvider.notifier);

  if (pdf.selectedPlacementIndex != null) {
    final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
    if (pdf.selectedPlacementIndex! < placements.length) {
      final currentRect = placements[pdf.selectedPlacementIndex!].rect;
      TestWorld.prevCenter = currentRect.center;

      // Resize and move the placement
      final newRect = Rect.fromCenter(
        center: currentRect.center + const Offset(20, -10),
        width: currentRect.width + 50,
        height: currentRect.height + 30,
      );

      pdfN.updatePlacementRect(
        page: pdf.currentPage,
        index: pdf.selectedPlacementIndex!,
        rect: newRect,
      );
    }
  }
}
