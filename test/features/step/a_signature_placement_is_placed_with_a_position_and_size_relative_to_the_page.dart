import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: a signature placement is placed with a position and size relative to the page
Future<void> aSignaturePlacementIsPlacedWithAPositionAndSizeRelativeToThePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(pdfProvider);
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: pdf.currentPage,
        rect: Rect.fromLTWH(50, 50, 200, 100),
        assetId: 'test.png',
      );
}
