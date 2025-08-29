import 'dart:math' as math;
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart' as printing;

import '../../../../data/model/model.dart';
import '../../../../data/services/providers.dart';
import '../view_model/view_model.dart';
import 'draw_canvas.dart';
import '../../preferences/widgets/settings_screen.dart';

class PdfSignatureHomePage extends ConsumerStatefulWidget {
  const PdfSignatureHomePage({super.key});

  @override
  ConsumerState<PdfSignatureHomePage> createState() =>
      _PdfSignatureHomePageState();
}

class _PdfSignatureHomePageState extends ConsumerState<PdfSignatureHomePage> {
  static const Size _pageSize = SignatureController.pageSize;
  final GlobalKey _captureKey = GlobalKey();

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

  // mark-for-signing removed; no toggle needed

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
    // When a signature is added, set the current page as signed.
    final p = ref.read(pdfProvider);
    if (p.loaded) {
      ref.read(pdfProvider.notifier).setSignedPage(p.currentPage);
    }
  }

  void _createNewSignature() {
    // Create a movable signature (draft) that won't be exported until confirmed
    final sig = ref.read(signatureProvider.notifier);
    if (ref.read(pdfProvider).loaded) {
      sig.placeDefaultRect();
      ref
          .read(pdfProvider.notifier)
          .setSignedPage(ref.read(pdfProvider).currentPage);
      // Hint: how to confirm/delete via context menu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Long-press or right-click the signature to Confirm or Delete.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmSignature() {
    // Confirm: make current signature immutable and eligible for export by placing it
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

  Future<void> _showContextMenuForPlaced({
    required Offset globalPos,
    required int index,
  }) async {
    // Opening the menu implicitly selects the item
    _onSelectPlaced(index);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          key: Key('ctx_delete_signature'),
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );
    if (choice == null) return;
    if (choice == 'delete') {
      final currentPage = ref.read(pdfProvider).currentPage;
      ref
          .read(pdfProvider.notifier)
          .removePlacement(page: currentPage, index: index);
    }
  }

  Future<void> _openDrawCanvas() async {
    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => const DrawCanvas(),
    );
    if (result != null && result.isNotEmpty) {
      // Use the drawn image as signature content
      ref.read(signatureProvider.notifier).setImageBytes(result);
      // Mark current page as signed when a signature is created
      final p = ref.read(pdfProvider);
      if (p.loaded) {
        ref.read(pdfProvider.notifier).setSignedPage(p.currentPage);
      }
    }
  }

  Future<void> _saveSignedPdf() async {
    // Set exporting state to show loading overlay and block interactions
    ref.read(exportingProvider.notifier).state = true;
    try {
      final pdf = ref.read(pdfProvider);
      final sig = ref.read(signatureProvider);
      // Cache messenger before any awaits to avoid using BuildContext across async gaps.
      final messenger = ScaffoldMessenger.of(context);
      if (!pdf.loaded || sig.rect == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).nothingToSaveYet),
          ), // guard per use-case
        );
        return;
      }
      final exporter = ref.read(exportServiceProvider);
      final targetDpi = ref.read(exportDpiProvider);
      final useMock = ref.read(useMockViewerProvider);
      bool ok = false;
      String? savedPath;
      if (kIsWeb) {
        // Web: prefer using picked bytes; share via Printing
        Uint8List? src = pdf.pickedPdfBytes;
        if (src == null) {
          ok = false;
        } else {
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
          } else {
            ok = false;
          }
        }
      } else {
        // Desktop/mobile: choose between bytes or file-based export
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
            // In mock mode for tests, simulate success without file IO
            ok = out != null;
          } else if (out != null) {
            ok = await exporter.saveBytesToFile(
              bytes: out,
              outputPath: fullPath,
            );
          } else {
            ok = false;
          }
        } else if (pdf.pickedPdfPath != null) {
          if (useMock) {
            // Simulate success in mock
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
        } else {
          ok = false;
        }
      }
      if (!kIsWeb) {
        // Desktop/mobile: we had a concrete path
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
        // Web: indicate whether we triggered a download dialog
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
      // Clear exporting state when finished or on error
      ref.read(exportingProvider.notifier).state = false;
    }
  }

  String _ensurePdfExtension(String name) {
    if (!name.toLowerCase().endsWith('.pdf')) return '$name.pdf';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final pdf = ref.watch(pdfProvider);
    final isExporting = ref.watch(exportingProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(pdf, disabled: isExporting),
                const SizedBox(height: 8),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: isExporting,
                    child: _buildPageArea(pdf),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final sig = ref.watch(signatureProvider);
                    return sig.rect != null
                        ? AbsorbPointer(
                          absorbing: isExporting,
                          child: _buildAdjustmentsPanel(sig),
                        )
                        : const SizedBox.shrink();
                  },
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
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
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

  Widget _buildToolbar(PdfState pdf, {bool disabled = false}) {
    final dpi = ref.watch(exportDpiProvider);
    final l = AppLocalizations.of(context);
    final pageInfo = l.pageInfo(pdf.currentPage, pdf.pageCount);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          key: const Key('btn_open_settings'),
          onPressed:
              disabled
                  ? null
                  : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
          child: Text(l.settings),
        ),
        OutlinedButton(
          key: const Key('btn_open_pdf_picker'),
          onPressed: disabled ? null : _pickPdf,
          child: Text(l.openPdf),
        ),
        if (pdf.loaded) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('btn_prev'),
                onPressed:
                    disabled ? null : () => _jumpToPage(pdf.currentPage - 1),
                icon: const Icon(Icons.chevron_left),
                tooltip: l.prev,
              ),
              Text(pageInfo, key: const Key('lbl_page_info')),
              IconButton(
                key: const Key('btn_next'),
                onPressed:
                    disabled ? null : () => _jumpToPage(pdf.currentPage + 1),
                icon: const Icon(Icons.chevron_right),
                tooltip: l.next,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.goTo),
              SizedBox(
                width: 60,
                child: TextField(
                  key: const Key('txt_goto'),
                  keyboardType: TextInputType.number,
                  enabled: !disabled,
                  onSubmitted: (v) {
                    final n = int.tryParse(v);
                    if (n != null) _jumpToPage(n);
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.dpi),
              const SizedBox(width: 8),
              DropdownButton<double>(
                key: const Key('ddl_export_dpi'),
                value: dpi,
                items:
                    const [96.0, 144.0, 200.0, 300.0]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.toStringAsFixed(0)),
                          ),
                        )
                        .toList(),
                onChanged:
                    disabled
                        ? null
                        : (v) {
                          if (v != null) {
                            ref.read(exportDpiProvider.notifier).state = v;
                          }
                        },
              ),
            ],
          ),
          // Removed: Mark for signing button
          if (pdf.loaded)
            ElevatedButton(
              key: const Key('btn_save_pdf'),
              onPressed: disabled ? null : _saveSignedPdf,
              child: Text(l.saveSignedPdf),
            ),
          // Signature tools are available when a PDF is loaded
          OutlinedButton(
            key: const Key('btn_load_signature_picker'),
            onPressed: disabled || !pdf.loaded ? null : _loadSignatureFromFile,
            child: Text(l.loadSignatureFromFile),
          ),
          OutlinedButton(
            key: const Key('btn_create_signature'),
            onPressed: disabled || !pdf.loaded ? null : _createNewSignature,
            child: const Text('Create new signature'),
          ),
          ElevatedButton(
            key: const Key('btn_draw_signature'),
            onPressed: disabled || !pdf.loaded ? null : _openDrawCanvas,
            child: Text(l.drawSignature),
          ),
          // Confirm and Delete are available via context menus
        ],
      ],
    );
  }

  Widget _buildPageArea(PdfState pdf) {
    if (!pdf.loaded) {
      return Center(child: Text(AppLocalizations.of(context).noPdfLoaded));
    }
    final useMock = ref.watch(useMockViewerProvider);
    if (useMock) {
      return Center(
        child: AspectRatio(
          aspectRatio: _pageSize.width / _pageSize.height,
          child: RepaintBoundary(
            key: _captureKey,
            child: Stack(
              key: const Key('page_stack'),
              children: [
                Container(
                  key: ValueKey('pdf_page_view_${pdf.currentPage}'),
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).pageInfo(pdf.currentPage, pdf.pageCount),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final sig = ref.watch(signatureProvider);
                    final visible = ref.watch(signatureVisibilityProvider);
                    return visible
                        ? _buildPageOverlays(sig)
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
    // If a real PDF path is selected, show actual viewer. Otherwise, keep mock sample.
    if (pdf.pickedPdfPath != null) {
      return PdfDocumentViewBuilder.file(
        pdf.pickedPdfPath!,
        builder: (context, document) {
          if (document == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final pages = document.pages;
          final pageNum = pdf.currentPage.clamp(1, pages.length);
          final page = pages[pageNum - 1];
          final aspect = page.width / page.height;
          // Update page count in state if needed (post-frame to avoid build loop)
          if (pdf.pageCount != pages.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(pdfProvider.notifier).setPageCount(pages.length);
              }
            });
          }
          return Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: RepaintBoundary(
                key: _captureKey,
                child: Stack(
                  key: const Key('page_stack'),
                  children: [
                    PdfPageView(
                      key: ValueKey('pdf_page_view_$pageNum'),
                      document: document,
                      pageNumber: pageNum,
                      alignment: Alignment.center,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final sig = ref.watch(signatureProvider);
                        final visible = ref.watch(signatureVisibilityProvider);
                        return visible
                            ? _buildPageOverlays(sig)
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    // Fallback should not occur when not using mock; still return empty view
    return const SizedBox.shrink();
  }

  Widget _buildSignatureOverlay(
    SignatureState sig,
    Rect r, {
    bool interactive = true,
    int? placedIndex,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / _pageSize.width;
        final scaleY = constraints.maxHeight / _pageSize.height;
        final left = r.left * scaleX;
        final top = r.top * scaleY;
        final width = r.width * scaleX;
        final height = r.height * scaleY;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Builder(
                builder: (context) {
                  final selectedIdx =
                      ref.read(pdfProvider).selectedPlacementIndex;
                  final bool isPlaced = placedIndex != null;
                  final bool isSelected =
                      isPlaced && selectedIdx == placedIndex;
                  final Color borderColor =
                      isPlaced ? Colors.red : Colors.indigo;
                  final double borderWidth =
                      isPlaced ? (isSelected ? 3.0 : 2.0) : 2.0;
                  Widget content = DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        0,
                        0,
                        0,
                        0.05 + math.min(0.25, (sig.contrast - 1.0).abs()),
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final processed = ref.watch(
                              processedSignatureImageProvider,
                            );
                            final bytes = processed ?? sig.imageBytes;
                            if (bytes == null) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context).signature,
                                ),
                              );
                            }
                            return Image.memory(bytes, fit: BoxFit.contain);
                          },
                        ),
                        if (interactive)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              key: const Key('signature_handle'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate:
                                  (d) => _onResizeSignature(
                                    Offset(
                                      d.delta.dx / scaleX,
                                      d.delta.dy / scaleY,
                                    ),
                                  ),
                              child: const Icon(Icons.open_in_full, size: 20),
                            ),
                          ),
                        // No inline buttons for placed overlays; use context menu instead
                      ],
                    ),
                  );
                  if (interactive && sig.editingEnabled) {
                    content = GestureDetector(
                      key: const Key('signature_overlay'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) {},
                      onPanUpdate:
                          (d) => _onDragSignature(
                            Offset(d.delta.dx / scaleX, d.delta.dy / scaleY),
                          ),
                      onSecondaryTapDown: (d) {
                        // Context menu for active signature: confirm or delete draft (clear)
                        final pos = d.globalPosition;
                        showMenu<String>(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            pos.dx,
                            pos.dy,
                            pos.dx,
                            pos.dy,
                          ),
                          items: [
                            const PopupMenuItem<String>(
                              key: Key('ctx_active_confirm'),
                              value: 'confirm',
                              child: Text('Confirm'),
                            ),
                            const PopupMenuItem<String>(
                              key: Key('ctx_active_delete'),
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ).then((choice) {
                          if (choice == 'confirm') {
                            _confirmSignature();
                          } else if (choice == 'delete') {
                            ref
                                .read(signatureProvider.notifier)
                                .clearActiveOverlay();
                          }
                        });
                      },
                      onLongPressStart: (d) {
                        final pos = d.globalPosition;
                        showMenu<String>(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            pos.dx,
                            pos.dy,
                            pos.dx,
                            pos.dy,
                          ),
                          items: [
                            const PopupMenuItem<String>(
                              key: Key('ctx_active_confirm_lp'),
                              value: 'confirm',
                              child: Text('Confirm'),
                            ),
                            const PopupMenuItem<String>(
                              key: Key('ctx_active_delete_lp'),
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ).then((choice) {
                          if (choice == 'confirm') {
                            _confirmSignature();
                          } else if (choice == 'delete') {
                            ref
                                .read(signatureProvider.notifier)
                                .clearActiveOverlay();
                          }
                        });
                      },
                      child: content,
                    );
                  } else {
                    // For placed items: tap to select; long-press/right-click for context menu
                    content = GestureDetector(
                      key: Key('placed_signature_${placedIndex ?? 'x'}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onSelectPlaced(placedIndex),
                      onSecondaryTapDown: (d) {
                        if (placedIndex != null) {
                          _showContextMenuForPlaced(
                            globalPos: d.globalPosition,
                            index: placedIndex,
                          );
                        }
                      },
                      onLongPressStart: (d) {
                        if (placedIndex != null) {
                          _showContextMenuForPlaced(
                            globalPos: d.globalPosition,
                            index: placedIndex,
                          );
                        }
                      },
                      child: content,
                    );
                  }
                  return content;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageOverlays(SignatureState sig) {
    final pdf = ref.watch(pdfProvider);
    final current = pdf.currentPage;
    final placed = pdf.placementsByPage[current] ?? const <Rect>[];
    final widgets = <Widget>[];
    for (int i = 0; i < placed.length; i++) {
      final r = placed[i];
      widgets.add(
        _buildSignatureOverlay(sig, r, interactive: false, placedIndex: i),
      );
    }
    // Show the active editing rect only on the selected (signed) page
    if (sig.rect != null &&
        sig.editingEnabled &&
        (pdf.signedPage == null || pdf.signedPage == current)) {
      widgets.add(_buildSignatureOverlay(sig, sig.rect!, interactive: true));
    }
    return Stack(children: widgets);
  }

  Widget _buildAdjustmentsPanel(SignatureState sig) {
    return Column(
      key: const Key('adjustments_panel'),
      children: [
        Row(
          children: [
            Checkbox(
              key: const Key('chk_aspect_lock'),
              value: sig.aspectLocked,
              onChanged:
                  (v) => ref
                      .read(signatureProvider.notifier)
                      .toggleAspect(v ?? false),
            ),
            Text(AppLocalizations.of(context).lockAspectRatio),
            const SizedBox(width: 16),
            Switch(
              key: const Key('swt_bg_removal'),
              value: sig.bgRemoval,
              onChanged:
                  (v) => ref.read(signatureProvider.notifier).setBgRemoval(v),
            ),
            Text(AppLocalizations.of(context).backgroundRemoval),
          ],
        ),
        Row(
          children: [
            Text(AppLocalizations.of(context).contrast),
            Expanded(
              child: Slider(
                key: const Key('sld_contrast'),
                min: 0.0,
                max: 2.0,
                value: sig.contrast,
                onChanged:
                    (v) => ref.read(signatureProvider.notifier).setContrast(v),
              ),
            ),
            Text(sig.contrast.toStringAsFixed(2)),
          ],
        ),
        Row(
          children: [
            Text(AppLocalizations.of(context).brightness),
            Expanded(
              child: Slider(
                key: const Key('sld_brightness'),
                min: -1.0,
                max: 1.0,
                value: sig.brightness,
                onChanged:
                    (v) =>
                        ref.read(signatureProvider.notifier).setBrightness(v),
              ),
            ),
            Text(sig.brightness.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }
}
