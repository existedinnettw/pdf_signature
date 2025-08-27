import 'dart:math' as math;
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'dart:typed_data';
import '../share/export_service.dart';
import 'package:hand_signature/signature.dart' as hand;
import 'package:meta/meta.dart';

part 'viewer_state.dart';
part 'viewer_widgets.dart';

// Testing hook: allow using a mock viewer instead of pdfrx to avoid async I/O in widget tests
final useMockViewerProvider = Provider<bool>((_) => false);
// Export service injection for testability
final exportServiceProvider = Provider<ExportService>((_) => ExportService());
// Export DPI setting (points per inch mapping), default 144 DPI
final exportDpiProvider = StateProvider<double>((_) => 144.0);
// Controls whether signature overlay is visible (used to hide on non-stamped pages during export)
final signatureVisibilityProvider = StateProvider<bool>((_) => true);
// Save path picker (injected for tests)
final savePathPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    String? initialDir;
    try {
      final d = await pp.getDownloadsDirectory();
      initialDir = d?.path;
    } catch (_) {}
    if (initialDir == null) {
      try {
        final d = await pp.getApplicationDocumentsDirectory();
        initialDir = d.path;
      } catch (_) {}
    }
    final location = await fs.getSaveLocation(
      suggestedName: 'signed.pdf',
      acceptedTypeGroups: [
        const fs.XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
      initialDirectory: initialDir,
    );
    if (location == null) return null;
    final path = location.path;
    return path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
  };
});

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
      ref.read(pdfProvider.notifier).openPicked(path: file.path);
      ref.read(signatureProvider.notifier).resetForNewPage();
    }
  }

  void _jumpToPage(int page) {
    ref.read(pdfProvider.notifier).jumpTo(page);
  }

  void _toggleMarkForSigning() {
    ref.read(pdfProvider.notifier).toggleMark();
  }

  Future<void> _loadSignatureFromFile() async {
    final pdf = ref.read(pdfProvider);
    if (!pdf.markedForSigning) return;
    final typeGroup = const fs.XTypeGroup(
      label: 'Image',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final sig = ref.read(signatureProvider.notifier);
    sig.setImageBytes(bytes);
  }

  // removed invalid loader; not part of normal app

  void _onDragSignature(Offset delta) {
    ref.read(signatureProvider.notifier).drag(delta);
  }

  void _onResizeSignature(Offset delta) {
    ref.read(signatureProvider.notifier).resize(delta);
  }

  Future<void> _openDrawCanvas() async {
    final pdf = ref.read(pdfProvider);
    if (!pdf.markedForSigning) return;
    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => const DrawCanvas(),
    );
    if (result != null && result.isNotEmpty) {
      // Use the drawn image as signature content
      ref.read(signatureProvider.notifier).setImageBytes(result);
    }
  }

  Future<void> _saveSignedPdf() async {
    final pdf = ref.read(pdfProvider);
    final sig = ref.read(signatureProvider);
    if (!pdf.loaded || sig.rect == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to save yet'),
        ), // guard per use-case
      );
      return;
    }
    final pick = ref.read(savePathPickerProvider);
    final path = await pick();
    if (path == null || path.trim().isEmpty) return;
    final fullPath = _ensurePdfExtension(path.trim());
    final exporter = ref.read(exportServiceProvider);
    final targetDpi = ref.read(exportDpiProvider);
    // Multi-page export: iterate pages by navigating the viewer
    final controller = ref.read(pdfProvider.notifier);
    final current = pdf.currentPage;
    final targetPage = pdf.signedPage; // may be null if not marked
    final ok = await exporter.exportMultiPageFromBoundary(
      boundaryKey: _captureKey,
      outputPath: fullPath,
      pageCount: pdf.pageCount,
      targetDpi: targetDpi,
      onGotoPage: (p) async {
        controller.jumpTo(p);
        // Show overlay only on the signed page (if any)
        // If a target page is specified, show overlay only on that page.
        // If not specified, keep overlay visible (backwards compatible single-page case).
        final show = targetPage == null ? true : (targetPage == p);
        ref.read(signatureVisibilityProvider.notifier).state = show;
        // Allow build to occur
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );
    // Restore page
    controller.jumpTo(current);
    // Restore visibility
    ref.read(signatureVisibilityProvider.notifier).state = true;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: $fullPath')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save PDF')));
    }
  }

  // Removed manual full-path dialog; using file_selector.getSaveLocation via provider

  String _ensurePdfExtension(String name) {
    if (!name.toLowerCase().endsWith('.pdf')) return '$name.pdf';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final pdf = ref.watch(pdfProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Signature')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildToolbar(pdf),
            const SizedBox(height: 8),
            Expanded(child: _buildPageArea(pdf)),
            Consumer(
              builder: (context, ref, _) {
                final sig = ref.watch(signatureProvider);
                return sig.rect != null
                    ? _buildAdjustmentsPanel(sig)
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(PdfState pdf) {
    final dpi = ref.watch(exportDpiProvider);
    final pageInfo = 'Page ${pdf.currentPage}/${pdf.pageCount}';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          key: const Key('btn_open_pdf_picker'),
          onPressed: _pickPdf,
          child: const Text('Open PDF...'),
        ),
        if (pdf.loaded) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('btn_prev'),
                onPressed: () => _jumpToPage(pdf.currentPage - 1),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Prev',
              ),
              Text(pageInfo, key: const Key('lbl_page_info')),
              IconButton(
                key: const Key('btn_next'),
                onPressed: () => _jumpToPage(pdf.currentPage + 1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Go to:'),
              SizedBox(
                width: 60,
                child: TextField(
                  key: const Key('txt_goto'),
                  keyboardType: TextInputType.number,
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
              const Text('DPI:'),
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
                onChanged: (v) {
                  if (v != null) {
                    ref.read(exportDpiProvider.notifier).state = v;
                  }
                },
              ),
            ],
          ),
          ElevatedButton(
            key: const Key('btn_mark_signing'),
            onPressed: _toggleMarkForSigning,
            child: Text(
              pdf.markedForSigning ? 'Unmark Signing' : 'Mark for Signing',
            ),
          ),
          if (pdf.loaded)
            ElevatedButton(
              key: const Key('btn_save_pdf'),
              onPressed: _saveSignedPdf,
              child: const Text('Save Signed PDF'),
            ),
          if (pdf.markedForSigning) ...[
            OutlinedButton(
              key: const Key('btn_load_signature_picker'),
              onPressed: _loadSignatureFromFile,
              child: const Text('Load Signature from file'),
            ),
            ElevatedButton(
              key: const Key('btn_draw_signature'),
              onPressed: _openDrawCanvas,
              child: const Text('Draw Signature'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPageArea(PdfState pdf) {
    if (!pdf.loaded) {
      return const Center(child: Text('No PDF loaded'));
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
                  key: const Key('pdf_page'),
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      'Page ${pdf.currentPage}/${pdf.pageCount}',
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
                    return sig.rect != null && visible
                        ? _buildSignatureOverlay(sig)
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
                      document: document,
                      pageNumber: pageNum,
                      alignment: Alignment.center,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final sig = ref.watch(signatureProvider);
                        final visible = ref.watch(signatureVisibilityProvider);
                        return sig.rect != null && visible
                            ? _buildSignatureOverlay(sig)
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

  Widget _buildSignatureOverlay(SignatureState sig) {
    final r = sig.rect!;
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
              child: GestureDetector(
                key: const Key('signature_overlay'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {},
                onPanUpdate:
                    (d) => _onDragSignature(
                      Offset(d.delta.dx / scaleX, d.delta.dy / scaleY),
                    ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.05 + math.min(0.25, (sig.contrast - 1.0).abs()),
                    ),
                    border: Border.all(color: Colors.indigo, width: 2),
                  ),
                  child: Stack(
                    children: [
                      if (sig.imageBytes != null)
                        Image.memory(sig.imageBytes!, fit: BoxFit.contain)
                      else
                        const Center(child: Text('Signature')),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
            const Text('Lock aspect ratio'),
            const SizedBox(width: 16),
            Switch(
              key: const Key('swt_bg_removal'),
              value: sig.bgRemoval,
              onChanged:
                  (v) => ref.read(signatureProvider.notifier).setBgRemoval(v),
            ),
            const Text('Background removal'),
          ],
        ),
        Row(
          children: [
            const Text('Contrast'),
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
            const Text('Brightness'),
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
