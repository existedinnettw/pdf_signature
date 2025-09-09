import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import 'package:pdf_signature/data/repositories/signature_library_repository.dart';
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
