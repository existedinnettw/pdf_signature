import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: a document is open with no signature placements placed
Future<void> aDocumentIsOpenWithNoSignaturePlacementsPlaced(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(documentRepositoryProvider.notifier)
      .openPicked(path: 'empty.pdf', pageCount: 5);
  // No placements added
}
