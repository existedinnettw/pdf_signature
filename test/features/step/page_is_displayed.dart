import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: page {1} is displayed
Future<void> pageIsDisplayed(WidgetTester tester, num param1) async {
  final expected = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  expect(c.read(documentRepositoryProvider).currentPage, expected);
}
