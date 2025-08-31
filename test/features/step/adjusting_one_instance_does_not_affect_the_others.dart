import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: adjusting one instance does not affect the others
Future<void> adjustingOneInstanceDoesNotAffectTheOthers(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final before = container.read(pdfProvider.notifier).placementsOn(2);
  expect(before.length, greaterThanOrEqualTo(2));
  final modified = before[0].translate(5, 0).inflate(3);
  container.read(pdfProvider.notifier).removePlacement(page: 2, index: 0);
  container.read(pdfProvider.notifier).addPlacement(page: 2, rect: modified);
  final after = container.read(pdfProvider.notifier).placementsOn(2);
  expect(after.any((r) => r == before[1]), isTrue);
}
