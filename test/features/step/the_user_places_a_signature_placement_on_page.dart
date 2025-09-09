import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user places a signature placement on page {1}
Future<void> theUserPlacesASignaturePlacementOnPage(
  WidgetTester tester,
  num param1,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final page = param1.toInt();
  container
      .read(pdfProvider.notifier)
      .addPlacement(
        page: page,
        rect: Rect.fromLTWH(20, 20, 100, 50),
        assetId: 'test.png',
      );
}
