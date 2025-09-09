import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the left pages overview highlights page {5}
Future<void> theLeftPagesOverviewHighlightsPage(
  WidgetTester tester,
  num param1,
) async {
  final n = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  expect(c.read(pdfProvider).currentPage, n);
}
