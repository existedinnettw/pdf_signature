import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewModel extends ChangeNotifier {
  final Ref ref;
  PdfViewerController _controller = PdfViewerController();
  PdfViewerController get controller => _controller;
  int _currentPage = 1;
  late final bool _useMockViewer;

  // Active rect for signature placement overlay
  Rect? _activeRect;
  Rect? get activeRect => _activeRect;
  set activeRect(Rect? value) {
    _activeRect = value;
    notifyListeners();
  }

  // const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  PdfViewModel(this.ref, {bool? useMockViewer})
    : _useMockViewer =
          useMockViewer ??
          bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  bool get useMockViewer => _useMockViewer;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    _currentPage = value.clamp(1, document.pageCount);

    notifyListeners();
  }

  Document get document => ref.watch(documentRepositoryProvider);

  void jumpToPage(int page) {
    currentPage = page;
  }

  // Make this view model "int-like" for tests that compare it directly to an
  // integer or use it as a Map key for page lookups.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is int) {
      return other == currentPage;
    }
    return false;
  }

  @override
  int get hashCode => currentPage.hashCode;

  // Allow repositories to request a UI refresh without mutating provider state
  void notifyPlacementsChanged() {
    notifyListeners();
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
    clearAllSignatureCards();

    currentPage = 1; // Reset current page to 1
  }

  // Document repository methods
  void closeDocument() {
    ref.read(documentRepositoryProvider.notifier).close();
  }

  void setPageCount(int count) {
    ref.read(documentRepositoryProvider.notifier).setPageCount(count);
  }

  void addPlacement({
    required int page,
    required Rect rect,
    SignatureAsset? asset,
    double rotationDeg = 0.0,
    GraphicAdjust? graphicAdjust,
  }) {
    ref
        .read(documentRepositoryProvider.notifier)
        .addPlacement(
          page: page,
          rect: rect,
          asset: asset,
          rotationDeg: rotationDeg,
          graphicAdjust: graphicAdjust,
        );
  }

  void updatePlacementRotation({
    required int page,
    required int index,
    required double rotationDeg,
  }) {
    ref
        .read(documentRepositoryProvider.notifier)
        .updatePlacementRotation(
          page: page,
          index: index,
          rotationDeg: rotationDeg,
        );
  }

  void removePlacement({required int page, required int index}) {
    ref
        .read(documentRepositoryProvider.notifier)
        .removePlacement(page: page, index: index);
  }

  void updatePlacementRect({
    required int page,
    required int index,
    required Rect rect,
  }) {
    ref
        .read(documentRepositoryProvider.notifier)
        .updatePlacementRect(page: page, index: index, rect: rect);
  }

  List<SignaturePlacement> placementsOn(int page) {
    return ref.read(documentRepositoryProvider.notifier).placementsOn(page);
  }

  SignatureAsset? assetOfPlacement({required int page, required int index}) {
    return ref
        .read(documentRepositoryProvider.notifier)
        .assetOfPlacement(page: page, index: index);
  }

  Future<void> exportDocument({
    required String outputPath,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
  }) async {
    await ref
        .read(documentRepositoryProvider.notifier)
        .exportDocument(
          outputPath: outputPath,
          uiPageSize: uiPageSize,
          signatureImageBytes: signatureImageBytes,
        );
  }

  // Signature card repository methods
  List<SignatureCard> get signatureCards =>
      ref.read(signatureCardRepositoryProvider);

  void addSignatureCard(SignatureCard card) {
    ref.read(signatureCardRepositoryProvider.notifier).add(card);
  }

  void addSignatureCardWithAsset(SignatureAsset asset, double rotationDeg) {
    ref
        .read(signatureCardRepositoryProvider.notifier)
        .addWithAsset(asset, rotationDeg);
  }

  void updateSignatureCard(
    SignatureCard card,
    double? rotationDeg,
    GraphicAdjust? graphicAdjust,
  ) {
    ref
        .read(signatureCardRepositoryProvider.notifier)
        .update(card, rotationDeg, graphicAdjust);
  }

  void removeSignatureCard(SignatureCard card) {
    ref.read(signatureCardRepositoryProvider.notifier).remove(card);
  }

  void clearAllSignatureCards() {
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
  }
}

final pdfViewModelProvider = ChangeNotifierProvider<PdfViewModel>((ref) {
  return PdfViewModel(ref);
});
