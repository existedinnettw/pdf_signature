import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the first page of the new document is displayed
Future<void> theFirstPageOfTheNewDocumentIsDisplayed(
  WidgetTester tester,
) async {
  final c = TestWorld.container ?? ProviderContainer();
  expect(c.read(pdfViewModelProvider).currentPage, 1);
}
