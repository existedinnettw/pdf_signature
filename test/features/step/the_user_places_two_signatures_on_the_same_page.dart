import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user places two signatures on the same page
Future<void> theUserPlacesTwoSignaturesOnTheSamePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  // First
  container.read(signatureProvider.notifier).placeDefaultRect();
  final r1 = container.read(signatureProvider).rect!;
  container.read(pdfProvider.notifier).addPlacement(page: 1, rect: r1);
  // Second (offset a bit)
  final r2 = r1.shift(const Offset(30, 30));
  container.read(pdfProvider.notifier).addPlacement(page: 1, rect: r2);
}

/// Usage: each signature can be dragged and resized independently
Future<void> eachSignatureCanBeDraggedAndResizedIndependently(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final list = container.read(pdfProvider.notifier).placementsOn(1);
  expect(list.length, greaterThanOrEqualTo(2));
  // Independence is modeled by distinct rects; ensure not equal and both within page
  expect(list[0], isNot(equals(list[1])));
  for (final r in list.take(2)) {
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.top, greaterThanOrEqualTo(0));
  }
}

/// Usage: dragging or resizing one does not change the other
Future<void> draggingOrResizingOneDoesNotChangeTheOther(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final list = container.read(pdfProvider.notifier).placementsOn(1);
  expect(list.length, greaterThanOrEqualTo(2));
  final before = List<Rect>.from(list.take(2));
  // Simulate changing the first only
  final changed = before[0].shift(const Offset(5, 5));
  container.read(pdfProvider.notifier).removePlacement(page: 1, index: 0);
  container.read(pdfProvider.notifier).addPlacement(page: 1, rect: changed);
  final after = container.read(pdfProvider.notifier).placementsOn(1);
  expect(after[0], isNot(equals(before[0])));
  // The other remains the same (order may differ after remove/add, check set containment)
  expect(after.any((r) => r == before[1]), isTrue);
}
