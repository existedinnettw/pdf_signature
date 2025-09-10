import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: dragging or resizing one does not change the other
Future<void> draggingOrResizingOneDoesNotChangeTheOther(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final list = container
      .read(documentRepositoryProvider.notifier)
      .placementsOn(1);
  expect(list.length, greaterThanOrEqualTo(2));
  final before = List<Rect>.from(list.take(2).map((p) => p.rect));
  // Simulate changing the first only
  final changed = before[0].inflate(5);
  container
      .read(documentRepositoryProvider.notifier)
      .removePlacement(page: 1, index: 0);
  container
      .read(documentRepositoryProvider.notifier)
      .addPlacement(
        page: 1,
        rect: changed,
        asset: list[1].asset,
        rotationDeg: list[1].rotationDeg,
      );
  final after = container
      .read(documentRepositoryProvider.notifier)
      .placementsOn(1);
  expect(after.any((p) => p.rect == before[1]), isTrue);
}
