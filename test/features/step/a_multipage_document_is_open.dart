import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a multi-page document is open
Future<void> aMultipageDocumentIsOpen(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(signatureAssetRepositoryProvider.notifier).state = [];
  container.read(documentRepositoryProvider.notifier).state =
      Document.initial();
  container.read(signatureCardProvider.notifier).state =
      SignatureCard.initial();
  container.read(currentRectProvider.notifier).state = null;
  container.read(editingEnabledProvider.notifier).state = false;
  container.read(aspectLockedProvider.notifier).state = false;
  container
      .read(documentRepositoryProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 5);
}
