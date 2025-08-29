import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: a signature is placed on page 2
Future<void> aSignatureIsPlacedOnPage2(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 8);
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: 2, rect: const Rect.fromLTWH(50, 100, 80, 40));
}

/// Usage: the user navigates to page 5 and places another signature
Future<void> theUserNavigatesToPage5AndPlacesAnotherSignature(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(pdfProvider.notifier).jumpTo(5);
  container
      .read(pdfProvider.notifier)
      .addPlacement(page: 5, rect: const Rect.fromLTWH(60, 120, 80, 40));
}

/// Usage: the signature on page 2 remains
Future<void> theSignatureOnPage2Remains(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(pdfProvider.notifier).placementsOn(2), isNotEmpty);
}

/// Usage: the signature on page 5 is shown on page 5
Future<void> theSignatureOnPage5IsShownOnPage5(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(pdfProvider.notifier).placementsOn(5), isNotEmpty);
}
