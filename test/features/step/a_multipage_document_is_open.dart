import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a multi-page document is open
Future<void> aMultipageDocumentIsOpen(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(signatureLibraryProvider.notifier).state = [];
  container.read(pdfProvider.notifier).state = PdfState.initial();
  container.read(signatureProvider.notifier).state = SignatureState.initial();
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 5);
}
