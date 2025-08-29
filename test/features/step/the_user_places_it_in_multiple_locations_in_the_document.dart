import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user places it in multiple locations in the document
Future<void> theUserPlacesItInMultipleLocationsInTheDocument(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final notifier = container.read(pdfProvider.notifier);
  // Always open a fresh doc to avoid state bleed between scenarios
  notifier.openPicked(path: 'mock.pdf', pageCount: 6);
  // Place two on page 2 and one on page 4
  notifier.addPlacement(page: 2, rect: const Rect.fromLTWH(10, 10, 80, 40));
  notifier.addPlacement(page: 2, rect: const Rect.fromLTWH(120, 50, 80, 40));
  notifier.addPlacement(page: 4, rect: const Rect.fromLTWH(20, 200, 100, 50));
}

/// Usage: identical signature instances appear in each location
Future<void> identicalSignatureInstancesAppearInEachLocation(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final state = container.read(pdfProvider);
  final p2 = state.placementsByPage[2] ?? const [];
  final p4 = state.placementsByPage[4] ?? const [];
  expect(p2.length, greaterThanOrEqualTo(2));
  expect(p4.length, greaterThanOrEqualTo(1));
}

/// Usage: adjusting one instance does not affect the others
Future<void> adjustingOneInstanceDoesNotAffectTheOthers(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final before = container.read(pdfProvider.notifier).placementsOn(2);
  expect(before.length, greaterThanOrEqualTo(2));
  final modified = before[0].inflate(5);
  container.read(pdfProvider.notifier).removePlacement(page: 2, index: 0);
  container.read(pdfProvider.notifier).addPlacement(page: 2, rect: modified);
  final after = container.read(pdfProvider.notifier).placementsOn(2);
  expect(after.any((r) => r == before[1]), isTrue);
}
