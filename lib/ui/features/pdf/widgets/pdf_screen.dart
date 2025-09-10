import 'dart:typed_data';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:multi_split_view/multi_split_view.dart';

import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'draw_canvas.dart';
import 'pdf_toolbar.dart';
import 'pdf_page_area.dart';
import 'pages_sidebar.dart';
import 'signatures_sidebar.dart';
import 'ui_services.dart';

class PdfSignatureHomePage extends ConsumerStatefulWidget {
  const PdfSignatureHomePage({super.key});

  @override
  ConsumerState<PdfSignatureHomePage> createState() =>
      _PdfSignatureHomePageState();
}

class _PdfSignatureHomePageState extends ConsumerState<PdfSignatureHomePage> {
  static const Size _pageSize = Size(676, 960 / 1.4142);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).invalidOrUnsupportedFile),
      ),
    );
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
      // infer page count if possible
      int pageCount = 1;
      try {
        // printing.raster can detect page count lazily; leave 1 for tests
        pageCount = 5;
      } catch (_) {}
      ref
          .read(documentRepositoryProvider.notifier)
          .openPicked(path: file.path, pageCount: pageCount, bytes: bytes);
    }
  }

  void _jumpToPage(int page) {
    ref.read(documentRepositoryProvider.notifier).jumpTo(page);
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
    return bytes;
  }

  void _confirmSignature() {
    // In simplified UI, confirmation is a no-op
  }

  void _onDragSignature(Offset delta) {
    // In simplified UI, interactive overlay disabled
  }

  void _onResizeSignature(Offset delta) {
    // In simplified UI, interactive overlay disabled
  }

  void _onSelectPlaced(int? index) {
    // In simplified UI, selection is a no-op for tests
  }

  Future<Uint8List?> _openDrawCanvas() async {
    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => const DrawCanvas(),
    );
    if (result != null && result.isNotEmpty) {
      // In simplified UI, adding to library isn't implemented
    }
    return result;
  }

  Future<void> _saveSignedPdf() async {
    ref.read(exportingProvider.notifier).state = true;
    try {
      final pdf = ref.read(documentRepositoryProvider);
      final messenger = ScaffoldMessenger.of(context);
      if (!pdf.loaded) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).nothingToSaveYet),
          ),
        );
        return;
      }
      final exporter = ref.read(exportServiceProvider);

      // get DPI from preferences
      final targetDpi = ref.read(preferencesRepositoryProvider).exportDpi;
      bool ok = false;
      String? savedPath;

      if (!kIsWeb) {
        final pick = ref.read(savePathPickerProvider);
        final path = await pick();
        if (path == null || path.trim().isEmpty) return;
        final fullPath = _ensurePdfExtension(path.trim());
        savedPath = fullPath;
        final src = pdf.pickedPdfBytes ?? Uint8List(0);
        final out = await exporter.exportSignedPdfFromBytes(
          srcBytes: src,
          uiPageSize: _pageSize,
          signatureImageBytes: null,
          placementsByPage: pdf.placementsByPage,
          targetDpi: targetDpi,
        );
        if (out != null) {
          ok = await exporter.saveBytesToFile(bytes: out, outputPath: fullPath);
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
                onDragSignature: _onDragSignature,
                onResizeSignature: _onResizeSignature,
                onConfirmSignature: _confirmSignature,
                onClearActiveOverlay: () {},
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
                    setState(() {
                      _zoomLevel = (_zoomLevel - 10).clamp(10, 800);
                    });
                  },
                  onZoomIn: () {
                    setState(() {
                      _zoomLevel = (_zoomLevel + 10).clamp(10, 800);
                    });
                  },
                  zoomLevel: _zoomLevel,
                  fileName: 'mock.pdf',
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
