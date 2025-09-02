import 'dart:typed_data';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:printing/printing.dart' as printing;
import 'package:pdfrx/pdfrx.dart';

import '../../../../data/services/providers.dart';
import '../view_model/view_model.dart';
import 'draw_canvas.dart';
import 'pdf_toolbar.dart';
import 'pdf_page_area.dart';
import 'pdf_pages_overview.dart';
import 'signature_drawer.dart';
// adjustments are available via ImageEditorDialog

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

  // Zoom is managed by pdfrx viewer (Ctrl +/- etc.). No custom zoom here.

  Future<void> _loadSignatureFromFile() async {
    final typeGroup = const fs.XTypeGroup(
      label: 'Image',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final sig = ref.read(signatureProvider.notifier);
    sig.setImageBytes(bytes);
    final p = ref.read(pdfProvider);
    if (p.loaded) {
      ref.read(pdfProvider.notifier).setSignedPage(p.currentPage);
    }
  }

  // _createNewSignature was removed as the toolbar no longer exposes this action.

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

  Future<void> _openDrawCanvas() async {
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
  void dispose() {
    super.dispose();
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
                  // zoomLevel omitted to avoid compact overflows in tight tests
                  fileName: ref.watch(pdfProvider).pickedPdfPath,
                  showPagesSidebar: _showPagesSidebar,
                  showSignaturesSidebar: _showSignaturesSidebar,
                  onTogglePagesSidebar:
                      () => setState(() {
                        _showPagesSidebar = !_showPagesSidebar;
                      }),
                  onToggleSignaturesSidebar:
                      () => setState(() {
                        _showSignaturesSidebar = !_showSignaturesSidebar;
                      }),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showPagesSidebar)
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 140,
                            maxWidth: 180,
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: const PdfPagesOverview(),
                          ),
                        ),
                      if (_showPagesSidebar) const SizedBox(width: 12),
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: isExporting,
                          child: PdfPageArea(
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
                      if (_showSignaturesSidebar) const SizedBox(width: 12),
                      if (_showSignaturesSidebar)
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 140,
                            maxWidth: 250,
                          ),
                          child: AbsorbPointer(
                            absorbing: isExporting,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: SignatureDrawer(
                                        disabled: isExporting,
                                        onLoadSignatureFromFile:
                                            _loadSignatureFromFile,
                                        onOpenDrawCanvas: _openDrawCanvas,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ElevatedButton(
                                      key: const Key('btn_save_pdf'),
                                      onPressed:
                                          isExporting ? null : _saveSignedPdf,
                                      child: Text(l.saveSignedPdf),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
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
