import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: both signatures are shown on their respective pages
Future<void> bothSignaturesAreShownOnTheirRespectivePages(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final p1 = container.read(pdfProvider.notifier).placementsOn(1);
  final p3 = container.read(pdfProvider.notifier).placementsOn(3);
  expect(p1, isNotEmpty);
  expect(p3, isNotEmpty);
}
