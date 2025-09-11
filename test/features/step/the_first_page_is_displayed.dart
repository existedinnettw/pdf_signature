import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the first page is displayed
Future<void> theFirstPageIsDisplayed(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final currentPage = container.read(pdfViewModelProvider);
  expect(currentPage, 1);
}
