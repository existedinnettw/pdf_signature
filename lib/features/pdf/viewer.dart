import 'dart:math' as math;
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import '../share/export_service.dart';

part 'viewer_state.dart';
part 'viewer_widgets.dart';

// Testing hook: allow using a mock viewer instead of pdfrx to avoid async I/O in widget tests
final useMockViewerProvider = Provider<bool>((_) => false);

class PdfSignatureHomePage extends ConsumerStatefulWidget {
  const PdfSignatureHomePage({super.key});

  @override
  ConsumerState<PdfSignatureHomePage> createState() =>
      _PdfSignatureHomePageState();
}

class _PdfSignatureHomePageState extends ConsumerState<PdfSignatureHomePage> {
  static const Size _pageSize = SignatureController.pageSize;
  final GlobalKey _captureKey = GlobalKey();

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

  void _loadInvalidSignature() {
    ref.read(signatureProvider.notifier).setInvalidSelected(context);
  }

  void _onDragSignature(Offset delta) {
    ref.read(signatureProvider.notifier).drag(delta);
  }

  void _onResizeSignature(Offset delta) {
    ref.read(signatureProvider.notifier).resize(delta);
  }

  Future<void> _openDrawCanvas() async {
    final pdf = ref.read(pdfProvider);
    if (!pdf.markedForSigning) return;
    final current = ref.read(signatureProvider).strokes;
    final result = await showModalBottomSheet<List<List<Offset>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DrawCanvas(strokes: current),
    );
    if (result != null) {
      ref.read(signatureProvider.notifier).setStrokes(result);
      ref.read(signatureProvider.notifier).ensureRectForStrokes();
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
    // Pick a directory to save (fallback when save-as dialog API isn't available)
    final dir = await fs.getDirectoryPath();
    if (dir == null) return;
    final sep = Platform.pathSeparator;
    final path = '$dir${sep}signed.pdf';
    final exporter = ExportService();
    final ok = await exporter.exportSignedPdfFromBoundary(
      boundaryKey: _captureKey,
      outputPath: path,
    );
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: $path')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save PDF')));
    }
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
            OutlinedButton(
              key: const Key('btn_load_invalid_signature'),
              onPressed: _loadInvalidSignature,
              child: const Text('Load Invalid'),
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
                    return sig.rect != null
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
                        return sig.rect != null
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
                      else if (sig.strokes.isNotEmpty)
                        CustomPaint(painter: StrokesPainter(sig.strokes))
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
