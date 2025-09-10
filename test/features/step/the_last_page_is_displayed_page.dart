import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the last page is displayed (page {5})
Future<void> theLastPageIsDisplayedPage(WidgetTester tester, num param1) async {
  final last = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  final pdf = c.read(documentRepositoryProvider);
  expect(pdf.pageCount, last);
  expect(pdf.currentPage, last);
}
