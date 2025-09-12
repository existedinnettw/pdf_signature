import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: a multi-page document is open
Future<void> aMultipageDocumentIsOpen(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(signatureAssetRepositoryProvider.notifier).state = [];
  container.read(documentRepositoryProvider.notifier).state =
      Document.initial();
  container.read(signatureCardRepositoryProvider.notifier).state = [
    SignatureCard.initial(),
  ];
  container.read(documentRepositoryProvider.notifier).openPicked(pageCount: 5);
  // Reset page state providers
  try {
    container.read(currentPageProvider.notifier).state = 1;
  } catch (_) {}
  try {
    container.read(pdfViewModelProvider.notifier).jumpToPage(1);
  } catch (_) {}
}
