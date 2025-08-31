import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: all placed signatures appear on their corresponding pages in the output
Future<void> allPlacedSignaturesAppearOnTheirCorrespondingPagesInTheOutput(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(pdfProvider.notifier).placementsOn(1), isNotEmpty);
  // One of 4 or 5 depending on scenario
  final p4 = container.read(pdfProvider.notifier).placementsOn(4);
  final p5 = container.read(pdfProvider.notifier).placementsOn(5);
  expect(p4.isNotEmpty || p5.isNotEmpty, isTrue);
  expect(TestWorld.lastExportBytes, isNotNull);
}
