import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the Go to input cannot be used
Future<void> theGoToInputCannotBeUsed(WidgetTester tester) async {
  final c = TestWorld.container ?? ProviderContainer();
  // Not loaded, currentPage should remain 1 even after jump attempt
  expect(c.read(pdfProvider).loaded, isFalse);
  final before = c.read(pdfProvider).currentPage;
  c.read(pdfProvider.notifier).jumpTo(3);
  final after = c.read(pdfProvider).currentPage;
  expect(before, equals(after));
}
