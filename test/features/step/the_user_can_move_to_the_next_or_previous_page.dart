import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user can move to the next or previous page
Future<void> theUserCanMoveToTheNextOrPreviousPage(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final vm = container.read(pdfViewModelProvider.notifier);
  expect(container.read(pdfViewModelProvider).currentPage, 1);
  vm.jumpToPage(2);
  expect(container.read(pdfViewModelProvider).currentPage, 2);
  vm.jumpToPage(1);
  expect(container.read(pdfViewModelProvider).currentPage, 1);
}
