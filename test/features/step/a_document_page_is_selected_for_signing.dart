import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: a document page is selected for signing
Future<void> aDocumentPageIsSelectedForSigning(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(documentRepositoryProvider.notifier).setSignedPage(1);
  container.read(documentRepositoryProvider.notifier).jumpTo(1);
}
