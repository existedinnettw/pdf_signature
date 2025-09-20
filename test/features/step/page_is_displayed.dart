import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: page {1} is displayed
Future<void> pageIsDisplayed(WidgetTester tester, num param1) async {
  final expected = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  final currentPage = c.read(pdfViewModelProvider).currentPage;
  expect(
    currentPage == expected,
    true,
    reason: 'Expected page $expected but got current=$currentPage',
  );
}
