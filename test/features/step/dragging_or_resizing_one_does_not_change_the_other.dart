import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: dragging or resizing one does not change the other
Future<void> draggingOrResizingOneDoesNotChangeTheOther(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final page = container.read(pdfViewModelProvider).currentPage;
  final list = container
      .read(documentRepositoryProvider.notifier)
      .placementsOn(page);
  expect(list.length, greaterThanOrEqualTo(2));
  // Capture rects independently (avoid invalidation by mutation)
  final firstRectBefore = list[0].rect;
  final secondRectBefore = list[1].rect;

  // Simulate modifying only the first placement's size
  final changedFirst = firstRectBefore.inflate(5);
  container
      .read(documentRepositoryProvider.notifier)
      .modifyPlacement(page: page, index: 0, rect: changedFirst);

  final after = container
      .read(documentRepositoryProvider.notifier)
      .placementsOn(page);
  expect(after.length, greaterThanOrEqualTo(2));
  // First changed, second unchanged
  expect(after[0].rect, isNot(equals(firstRectBefore)));
  expect(after[0].rect, equals(changedFirst));
  expect(after[1].rect, equals(secondRectBefore));
}
