import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the signatures appear on the corresponding page in the output
Future<void> theSignaturesAppearOnTheCorrespondingPageInTheOutput(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);
  final sig = container.read(signatureProvider);
  expect(pdf.signedPage, isNotNull);
  expect(sig.rect, isNotNull);
  expect(sig.imageBytes, isNotNull);
}
