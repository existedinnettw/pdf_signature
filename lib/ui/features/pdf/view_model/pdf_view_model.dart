import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/document_version.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

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

  // Document version tracking for UI consistency
  DocumentVersion _documentVersion = DocumentVersion.initial();

  // Get current document source name for PdfDocumentRefData
  String get documentSourceName {
    // Ensure document version is up to date, but only update if really needed
    _updateDocumentVersionIfNeeded();
    return _documentVersion.sourceName;
  }

  void _updateDocumentVersionIfNeeded() {
    final document = ref.read(documentRepositoryProvider);
    if (!identical(_documentVersion.lastBytes, document.pickedPdfBytes)) {
      _documentVersion = DocumentVersion(
        version: _documentVersion.version + 1,
        lastBytes: document.pickedPdfBytes,
      );
    }
  }

  // const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  PdfViewModel(this.ref, {bool? useMockViewer})
    : _useMockViewer =
          useMockViewer ??
          const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  bool get useMockViewer => _useMockViewer;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    _currentPage = value.clamp(1, document.pageCount);
    // ignore: avoid_print
    debugPrint('PdfViewModel.currentPage set to $_currentPage');
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Do not watch the document repository here; watching would cause this
  // ChangeNotifier to be disposed/recreated on every document change, which
  // resets transient UI state like locked placements. Read instead.
  Document get document => ref.read(documentRepositoryProvider);

  void jumpToPage(int page) {
    // ignore: avoid_print
    debugPrint('PdfViewModel.jumpToPage ' + page.toString());
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
  XFile _currentFile = XFile('');
  // Keep a human display name in addition to XFile, because on Linux via
  // xdg-desktop-portal the path can look like /run/user/.../doc/<UUID>, and
  // XFile.name derives from that basename, yielding a random UUID instead of
  // the actual filename the user selected. We preserve the picker/drop name
  // here to offer a sensible default like "signed_<original>.pdf".
  String _displayFileName = '';

  PdfSessionViewModel({required this.ref, required this.router});

  XFile get currentFile => _currentFile;
  String get displayFileName => _displayFileName;

  Future<void> pickAndOpenPdf() async {
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
      await openPdf(path: path, bytes: effectiveBytes, fileName: name);
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
  }) async {
    int pageCount = 1; // default
    try {
      // Defensive: ensure Pdfrx cache directory set (in case main init skipped in tests)
      if (Pdfrx.getCacheDirectory == null) {
        debugPrint(
          '[PdfSessionViewModel] Pdfrx.getCacheDirectory was null; setting temp directory',
        );
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
      final doc = await PdfDocument.openData(bytes);
      pageCount = doc.pages.length;
      debugPrint(
        '[PdfSessionViewModel] Opened PDF bytes length=${bytes.length} pages=$pageCount',
      );
    } catch (e, st) {
      debugPrint(
        '[PdfSessionViewModel] Failed to read PDF data from bytes error=$e',
      );
      debugPrint(st.toString());
    }
    if (path != null && path.isNotEmpty) {
      _currentFile = XFile(path);
    } else if ((fileName != null && fileName.isNotEmpty)) {
      // Keep in-memory XFile so .name is available for suggestion
      try {
        _currentFile = XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'application/pdf',
        );
      } catch (e, st) {
        _currentFile = XFile(fileName);
        debugPrint(
          '[PdfSessionViewModel] Failed to create XFile.fromData name=$fileName error=$e',
        );
        debugPrint(st.toString());
      }
    } else {
      _currentFile = XFile('');
    }

    // Update display name: prefer explicit fileName (from picker/drop),
    // fall back to basename of path, otherwise empty.
    if (fileName != null && fileName.isNotEmpty) {
      _displayFileName = fileName;
    } else if (path != null && path.isNotEmpty) {
      _displayFileName = path.split('/').last.split('\\').last;
    } else {
      _displayFileName = '';
    }
    debugPrint('[PdfSessionViewModel] Calling openPicked with bytes');
    ref.read(documentRepositoryProvider.notifier).openPicked(bytes: bytes);
    // Keep existing signature cards when opening a new document.
    // The feature "Open a different document will reset signature placements but keep signature cards"
    // relies on this behavior. Placements are reset by openPicked() above.
    debugPrint('[PdfSessionViewModel] Navigating to /pdf');
    router.go('/pdf');
    debugPrint('[PdfSessionViewModel] Notifying listeners after open');
    notifyListeners();
  }

  void closePdf() {
    ref.read(documentRepositoryProvider.notifier).close();
    ref.read(signatureCardRepositoryProvider.notifier).clearAll();
    _currentFile = XFile('');
    _displayFileName = '';
    router.go('/');
    notifyListeners();
  }
}

final pdfSessionViewModelProvider =
    ChangeNotifierProvider.family<PdfSessionViewModel, GoRouter>((ref, router) {
      return PdfSessionViewModel(ref: ref, router: router);
    });
