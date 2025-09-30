import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user drags handles to resize and drags to reposition
Future<void> theUserDragsHandlesToResizeAndDragsToReposition(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdfN = container.read(documentRepositoryProvider.notifier);
  final currentPage = container.read(pdfViewModelProvider).currentPage;

  final placements = pdfN.placementsOn(currentPage);
  if (placements.isNotEmpty) {
    final currentRect = placements[0].rect;
    TestWorld.prevCenter = currentRect.center;

    // Resize and move the placement
    final newRect = Rect.fromCenter(
      center: currentRect.center + const Offset(20, -10),
      width: currentRect.width + 50,
      height: currentRect.height + 30,
    );

    pdfN.modifyPlacement(page: currentPage, index: 0, rect: newRect);
  }
}
