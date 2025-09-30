import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: a sample multi-page document (5 pages) is available
Future<void> aSampleMultipageDocument5PagesIsAvailable(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(documentRepositoryProvider.notifier)
      .openPickedWithPageCount(pageCount: 5);
}
