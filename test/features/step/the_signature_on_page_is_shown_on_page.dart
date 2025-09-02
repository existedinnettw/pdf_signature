import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the signature on page {5} is shown on page {5}
Future<void> theSignatureOnPageIsShownOnPage(
  WidgetTester tester,
  num sourcePage,
  num targetPage,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final srcList = container
      .read(pdfProvider.notifier)
      .placementsOn(sourcePage.toInt());
  final tgtList = container
      .read(pdfProvider.notifier)
      .placementsOn(targetPage.toInt());
  // At least one exists on both
  expect(srcList, isNotEmpty);
  expect(tgtList, isNotEmpty);
}
