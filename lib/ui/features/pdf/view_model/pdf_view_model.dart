import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:go_router/go_router.dart';

class PdfViewModel extends ChangeNotifier {
  final Ref ref;
  PdfViewerController _controller = PdfViewerController();
  PdfViewerController get controller => _controller;
  int _currentPage = 1;
  late final bool _useMockViewer;
  bool _isDisposed = false;

  // Active rect for signature placement overlay
  Rect? _activeRect;
  Rect? get activeRect => _activeRect;
  set activeRect(Rect? value) {
    _activeRect = value;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Locked placements: Set of (page, index) tuples
  final Set<String> _lockedPlacements = {};
  Set<String> get lockedPlacements => Set.unmodifiable(_lockedPlacements);

  // const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  PdfViewModel(this.ref, {bool? useMockViewer})
    : _useMockViewer =
          useMockViewer ??
          bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  bool get useMockViewer => _useMockViewer;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    _currentPage = value.clamp(1, document.pageCount);
    if (!_isDisposed) {
      notifyListeners();
    }
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
    if (!_isDisposed) {
      notifyListeners();
    }
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
    // Also remove from locked placements if it was locked
    _lockedPlacements.remove(_placementKey(page, index));
    if (!_isDisposed) {
      notifyListeners();
    }
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

  // Helper method to create a unique key for a placement
  String _placementKey(int page, int index) => '${page}_${index}';

  // Check if a placement is locked
  bool isPlacementLocked({required int page, required int index}) {
    return _lockedPlacements.contains(_placementKey(page, index));
  }

  // Lock a placement
  void lockPlacement({required int page, required int index}) {
    _lockedPlacements.add(_placementKey(page, index));
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Unlock a placement
  void unlockPlacement({required int page, required int index}) {
    _lockedPlacements.remove(_placementKey(page, index));
    if (!_isDisposed) {
      notifyListeners();
    }
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

final pdfViewModelProvider = ChangeNotifierProvider<PdfViewModel>((ref) {
  return PdfViewModel(ref);
});

/// ViewModel managing PDF session lifecycle (file picking/open/close) and
/// navigation. Replaces the previous PdfManager helper.
class PdfSessionViewModel extends ChangeNotifier {
  final Ref ref;
  final GoRouter router;
  fs.XFile _currentFile = fs.XFile('');

  PdfSessionViewModel({required this.ref, required this.router});

  fs.XFile get currentFile => _currentFile;

  Future<void> pickAndOpenPdf() async {
    final typeGroup = const fs.XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }
      await openPdf(path: file.path, bytes: bytes);
    }
  }

  Future<void> openPdf({String? path, Uint8List? bytes}) async {
    int pageCount = 1; // default
    if (bytes != null) {
      try {
        final doc = await PdfDocument.openData(bytes);
        pageCount = doc.pages.length;
      } catch (_) {
        // ignore invalid bytes
      }
    }
    if (path != null) {
      _currentFile = fs.XFile(path);
    }
    ref
        .read(documentRepositoryProvider.notifier)
        .openPicked(pageCount: pageCount, bytes: bytes);
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
    router.go('/pdf');
    notifyListeners();
  }

  void closePdf() {
    ref.read(documentRepositoryProvider.notifier).close();
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
    _currentFile = fs.XFile('');
    router.go('/');
    notifyListeners();
  }
}

final pdfSessionViewModelProvider =
    ChangeNotifierProvider.family<PdfSessionViewModel, GoRouter>((ref, router) {
      return PdfSessionViewModel(ref: ref, router: router);
    });
