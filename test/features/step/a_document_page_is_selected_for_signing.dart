import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: a document page is selected for signing
Future<void> aDocumentPageIsSelectedForSigning(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Ensure a document is open
  final repo = container.read(documentRepositoryProvider.notifier);
  if (!container.read(documentRepositoryProvider).loaded) {
    repo.openPickedWithPageCount(pageCount: 5);
  }
  // Ensure current page is 1 for consistent subsequent steps
  try {
    container.read(pdfViewModelProvider.notifier).jumpToPage(1);
  } catch (_) {}
  repo.jumpTo(1);
}
