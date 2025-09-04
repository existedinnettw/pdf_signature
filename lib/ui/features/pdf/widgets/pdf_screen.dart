import 'dart:typed_data';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:printing/printing.dart' as printing;
import 'package:pdfrx/pdfrx.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../../../data/services/export_providers.dart';
import '../view_model/view_model.dart';
import 'draw_canvas.dart';
import 'pdf_toolbar.dart';
import 'pdf_page_area.dart';
import 'pages_sidebar.dart';
import 'signatures_sidebar.dart';

class PdfSignatureHomePage extends ConsumerStatefulWidget {
  const PdfSignatureHomePage({super.key});

  @override
  ConsumerState<PdfSignatureHomePage> createState() =>
      _PdfSignatureHomePageState();
}

class _PdfSignatureHomePageState extends ConsumerState<PdfSignatureHomePage> {
  static const Size _pageSize = SignatureController.pageSize;
  final PdfViewerController _viewerController = PdfViewerController();
  bool _showPagesSidebar = true;
  bool _showSignaturesSidebar = true;
  int _zoomLevel = 100; // percentage for display only

  // Split view controller to manage resizable sidebars without remounting the center area.
  late final MultiSplitViewController _splitController;
  late final List<Area> _areas;
  double _lastPagesWidth = 160;
  double _lastSignaturesWidth = 220;
  // Configurable sidebar constraints
  final double _pagesMin = 100;
  final double _pagesMax = 250;
  final double _signaturesMin = 140;
  final double _signaturesMax = 250;

  // Exposed for tests to trigger the invalid-file SnackBar without UI.
  @visibleForTesting
  void debugShowInvalidSignatureSnackBar() {
    ref.read(signatureProvider.notifier).setInvalidSelected(context);
  }

  Future<void> _pickPdf() async {
    final typeGroup = const fs.XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }
      ref.read(pdfProvider.notifier).openPicked(path: file.path, bytes: bytes);
      ref.read(signatureProvider.notifier).resetForNewPage();
    }
  }

  void _jumpToPage(int page) {
    ref.read(pdfProvider.notifier).jumpTo(page);
  }

  Future<Uint8List?> _loadSignatureFromFile() async {
    final typeGroup = fs.XTypeGroup(
      label:
          Localizations.of<AppLocalizations>(context, AppLocalizations)?.image,
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final sig = ref.read(signatureProvider.notifier);
    sig.setImageBytes(bytes);
    final p = ref.read(pdfProvider);
    if (p.loaded) {
      ref.read(pdfProvider.notifier).setSignedPage(p.currentPage);
    }
    return bytes;
  }

  void _confirmSignature() {
    ref.read(signatureProvider.notifier).confirmCurrentSignature(ref);
  }

  void _onDragSignature(Offset delta) {
    ref.read(signatureProvider.notifier).drag(delta);
  }

  void _onResizeSignature(Offset delta) {
    ref.read(signatureProvider.notifier).resize(delta);
  }

  void _onSelectPlaced(int? index) {
    ref.read(pdfProvider.notifier).selectPlacement(index);
  }

  Future<Uint8List?> _openDrawCanvas() async {
    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => const DrawCanvas(),
    );
    if (result != null && result.isNotEmpty) {
      ref.read(signatureProvider.notifier).setImageBytes(result);
      final p = ref.read(pdfProvider);
      if (p.loaded) {
        ref.read(pdfProvider.notifier).setSignedPage(p.currentPage);
      }
    }
    return result;
  }

  Future<void> _saveSignedPdf() async {
    ref.read(exportingProvider.notifier).state = true;
    try {
      final pdf = ref.read(pdfProvider);
      final sig = ref.read(signatureProvider);
      final messenger = ScaffoldMessenger.of(context);
      if (!pdf.loaded || sig.rect == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).nothingToSaveYet),
          ),
        );
        return;
      }
      final exporter = ref.read(exportServiceProvider);
      final targetDpi = ref.read(exportDpiProvider);
      final useMock = ref.read(useMockViewerProvider);
      bool ok = false;
      String? savedPath;
      if (kIsWeb) {
        Uint8List? src = pdf.pickedPdfBytes;
        if (src != null) {
          final processed = ref.read(processedSignatureImageProvider);
          final bytes = await exporter.exportSignedPdfFromBytes(
            srcBytes: src,
            signedPage: pdf.signedPage,
            signatureRectUi: sig.rect,
            uiPageSize: SignatureController.pageSize,
            signatureImageBytes: processed ?? sig.imageBytes,
            placementsByPage: pdf.placementsByPage,
            placementImageByPage: pdf.placementImageByPage,
            libraryBytes: {
              for (final a in ref.read(signatureLibraryProvider)) a.id: a.bytes,
            },
            targetDpi: targetDpi,
          );
          if (bytes != null) {
            try {
              await printing.Printing.sharePdf(
                bytes: bytes,
                filename: 'signed.pdf',
              );
              ok = true;
            } catch (_) {
              ok = false;
            }
          }
        }
      } else {
        final pick = ref.read(savePathPickerProvider);
        final path = await pick();
        if (path == null || path.trim().isEmpty) return;
        final fullPath = _ensurePdfExtension(path.trim());
        savedPath = fullPath;
        if (pdf.pickedPdfBytes != null) {
          final processed = ref.read(processedSignatureImageProvider);
          final out = await exporter.exportSignedPdfFromBytes(
            srcBytes: pdf.pickedPdfBytes!,
            signedPage: pdf.signedPage,
            signatureRectUi: sig.rect,
            uiPageSize: SignatureController.pageSize,
            signatureImageBytes: processed ?? sig.imageBytes,
            placementsByPage: pdf.placementsByPage,
            placementImageByPage: pdf.placementImageByPage,
            libraryBytes: {
              for (final a in ref.read(signatureLibraryProvider)) a.id: a.bytes,
            },
            targetDpi: targetDpi,
          );
          if (useMock) {
            ok = out != null;
          } else if (out != null) {
            ok = await exporter.saveBytesToFile(
              bytes: out,
              outputPath: fullPath,
            );
          }
        } else if (pdf.pickedPdfPath != null) {
          if (useMock) {
            ok = true;
          } else {
            final processed = ref.read(processedSignatureImageProvider);
            ok = await exporter.exportSignedPdfFromFile(
              inputPath: pdf.pickedPdfPath!,
              outputPath: fullPath,
              signedPage: pdf.signedPage,
              signatureRectUi: sig.rect,
              uiPageSize: SignatureController.pageSize,
              signatureImageBytes: processed ?? sig.imageBytes,
              placementsByPage: pdf.placementsByPage,
              placementImageByPage: pdf.placementImageByPage,
              libraryBytes: {
                for (final a in ref.read(signatureLibraryProvider))
                  a.id: a.bytes,
              },
              targetDpi: targetDpi,
            );
          }
        }
      }
      if (!kIsWeb) {
        if (ok) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).savedWithPath(savedPath ?? ''),
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).failedToSavePdf),
            ),
          );
        }
      } else {
        if (ok) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).downloadStarted),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).failedToGeneratePdf),
            ),
          );
        }
      }
    } finally {
      ref.read(exportingProvider.notifier).state = false;
    }
  }

  String _ensurePdfExtension(String name) {
    if (!name.toLowerCase().endsWith('.pdf')) return '$name.pdf';
    return name;
  }

  @override
  void initState() {
    super.initState();
    // Build areas once with builders; keep these instances stable.
    _areas = [
      Area(
        size: _lastPagesWidth,
        min: _pagesMin,
        max: _pagesMax,
        builder:
            (context, area) => Offstage(
              offstage: !_showPagesSidebar,
              child: const PagesSidebar(),
            ),
      ),
      Area(
        flex: 1,
        builder:
            (context, area) => RepaintBoundary(
              child: PdfPageArea(
                key: const ValueKey('pdf_page_area'),
                pageSize: _pageSize,
                viewerController: _viewerController,
                onDragSignature: _onDragSignature,
                onResizeSignature: _onResizeSignature,
                onConfirmSignature: _confirmSignature,
                onClearActiveOverlay:
                    () =>
                        ref
                            .read(signatureProvider.notifier)
                            .clearActiveOverlay(),
                onSelectPlaced: _onSelectPlaced,
              ),
            ),
      ),
      Area(
        size: _lastSignaturesWidth,
        min: _signaturesMin,
        max: _signaturesMax,
        builder:
            (context, area) => Offstage(
              offstage: !_showSignaturesSidebar,
              child: SignaturesSidebar(
                onLoadSignatureFromFile: _loadSignatureFromFile,
                onOpenDrawCanvas: _openDrawCanvas,
                onSave: _saveSignedPdf,
              ),
            ),
      ),
    ];
    _splitController = MultiSplitViewController(areas: _areas);
    // Apply initial collapse if needed
    _applySidebarVisibility();
  }

  @override
  void dispose() {
    _splitController.dispose();
    super.dispose();
  }

  void _applySidebarVisibility() {
    // Left pages sidebar
    final left = _splitController.areas[0];
    if (_showPagesSidebar) {
      left.max = _pagesMax;
      left.min = _pagesMin;
      left.size = _lastPagesWidth.clamp(_pagesMin, _pagesMax);
    } else {
      _lastPagesWidth = left.size ?? _lastPagesWidth;
      left.min = 0;
      left.max = 1;
      left.size = 1; // effectively hidden
    }
    // Right signatures sidebar
    final right = _splitController.areas[2];
    if (_showSignaturesSidebar) {
      right.max = _signaturesMax;
      right.min = _signaturesMin;
      right.size = _lastSignaturesWidth.clamp(_signaturesMin, _signaturesMax);
    } else {
      _lastSignaturesWidth = right.size ?? _lastSignaturesWidth;
      right.min = 0;
      right.max = 1;
      right.size = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExporting = ref.watch(exportingProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              children: [
                // Full-width toolbar row
                PdfToolbar(
                  disabled: isExporting,
                  onPickPdf: _pickPdf,
                  onJumpToPage: _jumpToPage,
                  onZoomOut: () {
                    if (_viewerController.isReady) {
                      _viewerController.zoomDown();
                    }
                    setState(() {
                      _zoomLevel = (_zoomLevel - 10).clamp(10, 800);
                    });
                  },
                  onZoomIn: () {
                    if (_viewerController.isReady) {
                      _viewerController.zoomUp();
                    }
                    setState(() {
                      _zoomLevel = (_zoomLevel + 10).clamp(10, 800);
                    });
                  },
                  zoomLevel: _zoomLevel,
                  fileName: ref.watch(pdfProvider).pickedPdfPath,
                  showPagesSidebar: _showPagesSidebar,
                  showSignaturesSidebar: _showSignaturesSidebar,
                  onTogglePagesSidebar:
                      () => setState(() {
                        _showPagesSidebar = !_showPagesSidebar;
                        _applySidebarVisibility();
                      }),
                  onToggleSignaturesSidebar:
                      () => setState(() {
                        _showSignaturesSidebar = !_showSignaturesSidebar;
                        _applySidebarVisibility();
                      }),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MultiSplitView(
                    controller: _splitController,
                    axis: Axis.horizontal,
                  ),
                ),
              ],
            ),
            if (isExporting)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          l.exportingPleaseWait,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
