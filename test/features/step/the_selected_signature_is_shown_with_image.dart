import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the selected signature is shown with image {"bob.png"}
Future<void> theSelectedSignatureIsShownWithImage(
  WidgetTester tester,
  String expected,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(pdfProvider);
  final page = pdf.currentPage;
  final idx =
      pdf.selectedPlacementIndex ??
      ((pdf.placementsByPage[page]?.length ?? 1) - 1);
  final name = container
      .read(pdfProvider.notifier)
      .imageOfPlacement(page: page, index: idx);
  expect(name, expected);
}
