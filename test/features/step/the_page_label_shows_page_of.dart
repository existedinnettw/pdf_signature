import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the page label shows "Page {5} of {5}"
Future<void> thePageLabelShowsPageOf(
  WidgetTester tester,
  num param1,
  num param2,
) async {
  final current = param1.toInt();
  final total = param2.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  final pdf = c.read(documentRepositoryProvider);
  expect(c.read(pdfViewModelProvider), current);
  expect(pdf.pageCount, total);
}
