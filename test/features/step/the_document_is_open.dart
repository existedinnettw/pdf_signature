import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the document is open
Future<void> theDocumentIsOpen(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);
  expect(pdf.loaded, isTrue);
  expect(pdf.pageCount, greaterThan(0));
}
