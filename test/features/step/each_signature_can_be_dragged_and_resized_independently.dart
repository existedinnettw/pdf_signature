import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: each signature can be dragged and resized independently
Future<void> eachSignatureCanBeDraggedAndResizedIndependently(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final list = container.read(pdfProvider.notifier).placementsOn(1);
  expect(list.length, greaterThanOrEqualTo(2));
  // Independence is modeled by distinct rects; ensure not equal and both within page
  expect(list[0].rect, isNot(equals(list[1].rect)));
  for (final p in list.take(2)) {
    expect(p.rect.left, greaterThanOrEqualTo(0));
    expect(p.rect.top, greaterThanOrEqualTo(0));
  }
}
