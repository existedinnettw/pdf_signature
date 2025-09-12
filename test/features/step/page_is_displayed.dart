import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: page {1} is displayed
Future<void> pageIsDisplayed(WidgetTester tester, num param1) async {
  final expected = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  final vm = c.read(pdfViewModelProvider);
  final legacy = c.read(currentPageProvider);
  expect(
    vm == expected || legacy == expected,
    true,
    reason: 'Expected page $expected but got vm=$vm current=$legacy',
  );
}
