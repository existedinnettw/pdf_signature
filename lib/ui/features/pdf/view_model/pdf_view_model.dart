import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewModel {
  final Ref ref;

  PdfViewModel(this.ref);

  Document get document => ref.read(documentRepositoryProvider);

  void jumpToPage(int page) {
    ref.read(documentRepositoryProvider.notifier).jumpTo(page);
  }

  Future<void> openPdf({required String path, Uint8List? bytes}) async {
    int pageCount = 1;
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
        .openPicked(path: path, pageCount: pageCount, bytes: bytes);
    ref.read(signatureCardProvider.notifier).clearAll();
  }

  Future<Uint8List?> loadSignatureFromFile() async {
    // This would need file picker, but since it's UI logic, perhaps keep in widget
    // For now, return null
    return null;
  }

  void confirmSignature() {
    // Need to implement based on original logic
  }

  void onDragSignature(Offset delta) {
    // Implement drag
  }

  void onResizeSignature(Offset delta) {
    // Implement resize
  }

  void onSelectPlaced(int? index) {
    // ref.read(documentRepositoryProvider.notifier).selectPlacement(index);
  }

  Future<void> saveSignedPdf() async {
    // Implement save logic
  }
}

final pdfViewModelProvider = Provider<PdfViewModel>((ref) {
  return PdfViewModel(ref);
});
