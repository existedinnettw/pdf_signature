import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: a document page is selected for signing
Future<void> aDocumentPageIsSelectedForSigning(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(pdfProvider.notifier).setSignedPage(1);
  container.read(pdfProvider.notifier).jumpTo(1);
}
