import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user can move to the next or previous page
Future<void> theUserCanMoveToTheNextOrPreviousPage(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdfN = container.read(documentRepositoryProvider.notifier);
  final pdf = container.read(documentRepositoryProvider);
  expect(pdf.currentPage, 1);
  pdfN.jumpTo(2);
  expect(container.read(documentRepositoryProvider).currentPage, 2);
  pdfN.jumpTo(1);
  expect(container.read(documentRepositoryProvider).currentPage, 1);
}
