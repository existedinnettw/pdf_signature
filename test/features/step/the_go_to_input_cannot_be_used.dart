import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the Go to input cannot be used
Future<void> theGoToInputCannotBeUsed(WidgetTester tester) async {
  final c = TestWorld.container ?? ProviderContainer();
  // Not loaded, currentPage should remain 1 even after jump attempt
  expect(c.read(documentRepositoryProvider).loaded, isFalse);
  final before = c.read(pdfViewModelProvider);
  // documentRepository jumpTo no longer changes page; ensure unchanged
  c.read(documentRepositoryProvider.notifier).jumpTo(3);
  final after = c.read(pdfViewModelProvider);
  expect(before, equals(after));
}
