import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: page {5} becomes visible in the scroll area
Future<void> pageBecomesVisibleInTheScrollArea(
  WidgetTester tester,
  num param1,
) async {
  final page = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  expect(c.read(pdfProvider).currentPage, page);
}
