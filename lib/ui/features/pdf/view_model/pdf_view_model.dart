// ignore_for_file: unnecessary_import
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/document_version.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_state.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_session_state.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PdfViewModel extends Notifier<PdfViewState> {
  @override
  PdfViewState build() {
    return PdfViewState.initial();
  }

  PdfViewerController get controller => state.controller;
  int get currentPage => state.currentPage;
  bool get useMockViewer => state.useMockViewer;
  Rect? get activeRect => state.activeRect;
  Set<String> get lockedPlacements => state.lockedPlacements;

  set activeRect(Rect? value) {
    state = state.copyWith(activeRect: value, clearActiveRect: value == null);
  }

  set currentPage(int value) {
    final doc = ref.read(documentRepositoryProvider);
    final clamped = value.clamp(1, doc.pageCount);
    debugPrint('PdfViewModel.currentPage set to $clamped');
    state = state.copyWith(currentPage: clamped);
  }

  // Get current document source name for PdfDocumentRefData
  String get documentSourceName {
    // Return the current source name without updating state
    // State updates should be done explicitly via updateDocumentVersionIfNeeded()
    return state.documentVersion.sourceName;
  }

  void updateDocumentVersionIfNeeded() {
    final document = ref.read(documentRepositoryProvider);
    if (!identical(state.documentVersion.lastBytes, document.pickedPdfBytes)) {
      state = state.copyWith(
        documentVersion: DocumentVersion(
          version: state.documentVersion.version + 1,
          lastBytes: document.pickedPdfBytes,
        ),
      );
    }
  }

  // Do not watch the document repository here; watching would cause this
  // notifier to be disposed/recreated on every document change, which
  // resets transient UI state like locked placements. Read instead.
  Document get document => ref.read(documentRepositoryProvider);

  void jumpToPage(int page) {
    debugPrint('PdfViewModel.jumpToPage $page');
    currentPage = page;
  }

  // Allow repositories to request a UI refresh without mutating provider state
  void notifyPlacementsChanged() {
    // Force a rebuild by updating state
    state = state.copyWith();
  }

  // Document repository methods
  // Lifecycle (open/close) removed: handled exclusively by PdfSessionViewModel.

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
        .modifyPlacement(page: page, index: index, rotationDeg: rotationDeg);
  }

  void removePlacement({required int page, required int index}) {
    ref
        .read(documentRepositoryProvider.notifier)
        .removePlacement(page: page, index: index);
    // Also remove from locked placements if it was locked
    final newLocked = Set<String>.from(state.lockedPlacements)
      ..remove(_placementKey(page, index));
    state = state.copyWith(lockedPlacements: newLocked);
  }

  void updatePlacementRect({
    required int page,
    required int index,
    required Rect rect,
  }) {
    ref
        .read(documentRepositoryProvider.notifier)
        .modifyPlacement(page: page, index: index, rect: rect);
  }

  List<SignaturePlacement> placementsOn(int page) {
    return ref.read(documentRepositoryProvider.notifier).placementsOn(page);
  }

  SignatureAsset? assetOfPlacement({required int page, required int index}) {
    return ref
        .read(documentRepositoryProvider.notifier)
        .assetOfPlacement(page: page, index: index);
  }

  // Helper method to create a unique key for a placement
  String _placementKey(int page, int index) => '${page}_${index}';

  // Check if a placement is locked
  bool isPlacementLocked({required int page, required int index}) {
    return state.lockedPlacements.contains(_placementKey(page, index));
  }

  // Lock a placement
  void lockPlacement({required int page, required int index}) {
    final newLocked = Set<String>.from(state.lockedPlacements)
      ..add(_placementKey(page, index));
    state = state.copyWith(lockedPlacements: newLocked);
  }

  // Unlock a placement
  void unlockPlacement({required int page, required int index}) {
    final newLocked = Set<String>.from(state.lockedPlacements)
      ..remove(_placementKey(page, index));
    state = state.copyWith(lockedPlacements: newLocked);
  }

  // Toggle lock state of a placement
  void togglePlacementLock({required int page, required int index}) {
    if (isPlacementLocked(page: page, index: index)) {
      unlockPlacement(page: page, index: index);
    } else {
      lockPlacement(page: page, index: index);
    }
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

final pdfViewModelProvider = NotifierProvider<PdfViewModel, PdfViewState>(
  PdfViewModel.new,
);

/// ViewModel managing PDF session lifecycle (file picking/open/close) and
/// navigation. Replaces the previous PdfManager helper.
class PdfSessionViewModel extends Notifier<PdfSessionState> {
  @override
  PdfSessionState build() {
    return PdfSessionState.initial();
  }

  XFile get currentFile => state.currentFile;
  String get displayFileName => state.displayFileName;

  Future<void> pickAndOpenPdf(GoRouter router) async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final String name = picked.name;
    final String? path = picked.path;
    final Uint8List? bytes = picked.bytes;
    Uint8List? effectiveBytes = bytes;
    if (effectiveBytes == null && path != null && path.isNotEmpty) {
      try {
        effectiveBytes = await XFile(path).readAsBytes();
      } catch (e, st) {
        effectiveBytes = null;
        debugPrint(
          '[PdfSessionViewModel] Failed to read PDF data from path=$path error=$e',
        );
        debugPrint(st.toString());
      }
    }
    if (effectiveBytes != null) {
      await openPdf(
        path: path,
        bytes: effectiveBytes,
        fileName: name,
        router: router,
      );
    } else {
      debugPrint(
        '[PdfSessionViewModel] No PDF data available to open (path=$path, name=$name)',
      );
    }
  }

  Future<void> openPdf({
    String? path,
    required Uint8List bytes,
    String? fileName,
    required GoRouter router,
  }) async {
    int pageCount = 1; // default
    try {
      // Defensive: ensure Pdfrx cache directory set (in case main init skipped in tests)
      if (Pdfrx.getCacheDirectory == null && !kIsWeb) {
        debugPrint('[PdfSessionViewModel] Setting Pdfrx cache directory (io)');
        try {
          final temp = await getTemporaryDirectory();
          Pdfrx.getCacheDirectory = () async => temp.path;
        } catch (e, st) {
          debugPrint(
            '[PdfSessionViewModel] Failed to set fallback cache dir error=$e',
          );
          debugPrint(st.toString());
        }
      }
      // Ensure engine initialized (safe multiple calls)
      pdfrxFlutterInitialize();
      final doc = await PdfDocument.openData(bytes);
      pageCount = doc.pages.length;
      debugPrint(
        '[PdfSessionViewModel] Opened PDF bytes length=${bytes.length} pages=$pageCount',
      );
      // Use fast path to populate repository BEFORE navigation so the first
      // build of PdfViewerWidget sees a loaded document and avoids showing
      // transient "No PDF loaded".
      ref
          .read(documentRepositoryProvider.notifier)
          .openDocument(
            bytes: bytes,
            pageCount: pageCount,
            knownPageCount: true,
          );
    } catch (e, st) {
      debugPrint(
        '[PdfSessionViewModel] Failed to read PDF data from bytes error=$e',
      );
      debugPrint(st.toString());
    }
    XFile newFile;
    if (path != null && path.isNotEmpty) {
      newFile = XFile(path);
    } else if ((fileName != null && fileName.isNotEmpty)) {
      // Keep in-memory XFile so .name is available for suggestion
      try {
        newFile = XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'application/pdf',
        );
      } catch (e, st) {
        newFile = XFile(fileName);
        debugPrint(
          '[PdfSessionViewModel] Failed to create XFile.fromData name=$fileName error=$e',
        );
        debugPrint(st.toString());
      }
    } else {
      newFile = XFile('');
    }

    // Update display name: prefer explicit fileName (from picker/drop),
    // fall back to basename of path, otherwise empty.
    String newDisplayFileName;
    if (fileName != null && fileName.isNotEmpty) {
      newDisplayFileName = fileName;
    } else if (path != null && path.isNotEmpty) {
      newDisplayFileName = path.split('/').last.split('\\').last;
    } else {
      newDisplayFileName = '';
    }

    state = state.copyWith(
      currentFile: newFile,
      displayFileName: newDisplayFileName,
    );

    // If fast path failed to set repository (e.g., exception earlier), fallback to async derive.
    if (ref.read(documentRepositoryProvider).pickedPdfBytes != bytes) {
      debugPrint(
        '[PdfSessionViewModel] Fallback deriving page count via openDocument',
      );
      ref.read(documentRepositoryProvider.notifier).openDocument(bytes: bytes);
    }
    // Keep existing signature cards when opening a new document.
    // The feature "Open a different document will reset signature placements but keep signature cards"
    // relies on this behavior. Placements are reset by openPicked() above.
    debugPrint('[PdfSessionViewModel] Navigating to /pdf');
    router.go('/pdf');
    debugPrint('[PdfSessionViewModel] State updated after open');
  }

  void closePdf(GoRouter router) {
    ref.read(documentRepositoryProvider.notifier).close();
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
    state = state.copyWith(currentFile: XFile(''), displayFileName: '');
    router.go('/');
  }
}

final pdfSessionViewModelProvider =
    NotifierProvider<PdfSessionViewModel, PdfSessionState>(
      PdfSessionViewModel.new,
    );
