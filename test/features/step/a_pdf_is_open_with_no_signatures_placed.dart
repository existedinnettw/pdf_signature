import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: a PDF is open with no signatures placed
Future<void> aPdfIsOpenWithNoSignaturesPlaced(WidgetTester tester) async {
  // Fresh world for this scenario to avoid leftover rect/image from previous tests
  TestWorld.reset();
  final container = ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 1);
  container.read(signatureProvider.notifier).resetForNewPage();
}
