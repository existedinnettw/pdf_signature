import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the user can move to the next or previous page
Future<void> theUserCanMoveToTheNextOrPreviousPage(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdfN = container.read(pdfProvider.notifier);
  final pdf = container.read(pdfProvider);
  expect(pdf.currentPage, 1);
  pdfN.jumpTo(2);
  expect(container.read(pdfProvider).currentPage, 2);
  pdfN.jumpTo(1);
  expect(container.read(pdfProvider).currentPage, 1);
}
