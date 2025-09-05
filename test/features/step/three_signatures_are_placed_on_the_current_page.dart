import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: three signatures are placed on the current page
Future<void> threeSignaturesArePlacedOnTheCurrentPage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 5);
  final n = container.read(pdfProvider.notifier);
  n.addPlacement(page: 1, rect: const Rect.fromLTWH(10, 10, 80, 40));
  n.addPlacement(page: 1, rect: const Rect.fromLTWH(100, 50, 80, 40));
  n.addPlacement(page: 1, rect: const Rect.fromLTWH(200, 90, 80, 40));
}
