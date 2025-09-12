import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewModel extends StateNotifier<int> {
  final Ref ref;

  PdfViewModel(this.ref) : super(1);

  Document get document => ref.read(documentRepositoryProvider);

  void jumpToPage(int page) {
    state = page.clamp(1, document.pageCount);
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
        .openPicked(pageCount: pageCount, bytes: bytes);
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
    state = 1; // Reset current page to 1
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

final pdfViewModelProvider = StateNotifierProvider<PdfViewModel, int>((ref) {
  return PdfViewModel(ref);
});
