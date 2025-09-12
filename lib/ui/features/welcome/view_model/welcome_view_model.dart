import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdfrx/pdfrx.dart';

class WelcomeViewModel {
  final Ref ref;

  WelcomeViewModel(this.ref);

  Future<void> openPdf({required String path, Uint8List? bytes}) async {
    int pageCount = 1; // default
    if (bytes != null) {
      try {
        final doc = await PdfDocument.openData(bytes);
        pageCount = doc.pages.length;
      } catch (_) {
        // ignore
      }
    }
    ref
        .read(documentRepositoryProvider.notifier)
        .openPicked(pageCount: pageCount, bytes: bytes);
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
  }
}

final welcomeViewModelProvider = Provider<WelcomeViewModel>((ref) {
  return WelcomeViewModel(ref);
});
