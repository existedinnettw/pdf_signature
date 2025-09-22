import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:multi_split_view/multi_split_view.dart';

import 'package:pdfrx/pdfrx.dart';
import 'draw_canvas.dart';
import 'pdf_toolbar.dart';
import 'pdf_page_area.dart';
import 'pages_sidebar.dart';
import 'signatures_sidebar.dart';
import '../view_model/pdf_export_view_model.dart';
import 'package:pdf_signature/utils/download.dart';
import '../view_model/pdf_view_model.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:responsive_framework/responsive_framework.dart';

class PdfSignatureHomePage extends ConsumerStatefulWidget {
  final Future<void> Function() onPickPdf;
  final VoidCallback onClosePdf;
  final fs.XFile currentFile;
  // Optional display name for the currently opened file. On Linux
  // xdg-desktop-portal, XFile.name/path can be a UUID-like value. When
  // available, this name preserves the user-selected filename so we can
  // suggest a proper "signed_*.pdf" on save.
  final String? currentFileName;

  const PdfSignatureHomePage({
    super.key,
    required this.onPickPdf,
    required this.onClosePdf,
    required this.currentFile,
    this.currentFileName,
  });

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
  late PdfViewModel _viewModel;
  bool? _lastCanShowPagesSidebar;

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
    await widget.onPickPdf();
  }

  void _closePdf() {
    widget.onClosePdf();
  }

  void _jumpToPage(int page) {
    final controller = _viewModel.controller;
    final current = _viewModel.currentPage;
    final pdf = _viewModel.document;
    int target;
    if (page == -1) {
      target = (current - 1).clamp(1, pdf.pageCount);
    } else {
      target = page.clamp(1, pdf.pageCount);
    }
    // Update reactive page providers so UI/tests reflect navigation even if controller is a stub
    if (current != target) {
      // Also notify view model (if used elsewhere) via its public API
      try {
        _viewModel.jumpToPage(target);
      } catch (_) {
        // ignore if provider not available
      }
    }
    if (controller.isReady) controller.goToPage(pageNumber: target);
  }

  img.Image? _toStdSignatureImage(img.Image? image) {
    if (image == null) return null;
    image.convert(numChannels: 4);
    // Scale down if height > 256 to improve performance
    if (image.height > 256) {
      final newWidth = (image.width * 256) ~/ image.height;
      image = img.copyResize(image, width: newWidth, height: 256);
    }
    return image;
  }

  Future<img.Image?> _loadSignatureFromFile() async {
    final typeGroup = fs.XTypeGroup(
      label:
          Localizations.of<AppLocalizations>(context, AppLocalizations)?.image,
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    try {
      var sigImage = img.decodeImage(bytes);
      return _toStdSignatureImage(sigImage);
    } catch (_) {
      return null;
    }
  }

  Future<img.Image?> _openDrawCanvas() async {
    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => const DrawCanvas(),
    );
    if (result == null || result.isEmpty) return null;
    // In simplified UI, adding to library isn't implemented
    try {
      var sigImage = img.decodeImage(result);
      return _toStdSignatureImage(sigImage);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSignedPdf() async {
    // Show exporting overlay and then run the heavy work asynchronously so
    // the UI thread remains responsive to gestures like page navigation.
    ref.read(pdfExportViewModelProvider.notifier).setExporting(true);
    // ignore: avoid_print
    debugPrint('_saveSignedPdf: exporting flag set true');
    final weakContext = context;
    Future<void>(() async {
      try {
        // ignore: avoid_print
        debugPrint('_saveSignedPdf: async export task started');
        final pdf = _viewModel.document;
        final messenger = ScaffoldMessenger.of(weakContext);
        if (!pdf.loaded) {
          // ignore: avoid_print
          debugPrint('_saveSignedPdf: document not loaded');
          messenger.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(weakContext).nothingToSaveYet),
            ),
          );
          return;
        }
        // get DPI from preferences
        final targetDpi = ref.read(preferencesRepositoryProvider).exportDpi;
        bool ok = false;
        String? savedPath;

        // Derive a suggested filename based on the opened file.
        final display = widget.currentFileName;
        final originalName =
            (display != null && display.trim().isNotEmpty)
                ? display.trim()
                : widget.currentFile.name.isNotEmpty
                ? widget.currentFile.name
                : widget.currentFile.path.isNotEmpty
                ? widget.currentFile.path.split('/').last.split('\\').last
                : 'document.pdf';
        final suggested = _suggestSignedName(originalName);

        if (!kIsWeb) {
          final path = await ref
              .read(pdfExportViewModelProvider)
              .pickSavePathWithSuggestedName(suggested);
          if (path == null || path.trim().isEmpty) return;
          final fullPath = _ensurePdfExtension(path.trim());
          savedPath = fullPath;
          // ignore: avoid_print
          debugPrint('_saveSignedPdf: picked save path ' + fullPath);
          ok = await ref
              .read(pdfExportViewModelProvider)
              .exportToPath(
                outputPath: fullPath,
                uiPageSize: _pageSize,
                signatureImageBytes: null,
                targetDpi: targetDpi,
              );
          // ignore: avoid_print
          debugPrint('_saveSignedPdf: saveBytesToFile ok=' + ok.toString());
        } else {
          // Web: export and trigger browser download
          final out = await ref
              .read(documentRepositoryProvider.notifier)
              .exportDocumentToBytes(
                uiPageSize: _pageSize,
                signatureImageBytes: null,
                targetDpi: targetDpi,
              );
          if (out != null) {
            ok = await downloadBytes(out, filename: suggested);
            savedPath = suggested;
          }
        }
        if (!kIsWeb) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? AppLocalizations.of(
                      weakContext,
                    ).savedWithPath(savedPath ?? '')
                    : AppLocalizations.of(weakContext).failedToSavePdf,
              ),
            ),
          );
          // ignore: avoid_print
          debugPrint('_saveSignedPdf: SnackBar shown ok=' + ok.toString());
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? AppLocalizations.of(
                      weakContext,
                    ).savedWithPath(savedPath ?? 'signed.pdf')
                    : AppLocalizations.of(weakContext).failedToSavePdf,
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          ref.read(pdfExportViewModelProvider.notifier).setExporting(false);
          // ignore: avoid_print
          debugPrint('_saveSignedPdf: exporting flag set false');
        }
      }
    });
  }

  String _ensurePdfExtension(String name) {
    if (!name.toLowerCase().endsWith('.pdf')) return '$name.pdf';
    return name;
  }

  String _suggestSignedName(String original) {
    // Normalize to a base filename
    final base = original.split('/').last.split('\\').last;
    if (base.toLowerCase().endsWith('.pdf')) {
      return 'signed_' + base;
    }
    return 'signed_' + base + '.pdf';
  }

  void _onControllerChanged() {
    if (mounted) {
      if (_viewModel.controller.isReady) {
        final newZoomLevel = (_viewModel.controller.currentZoom * 100)
            .round()
            .clamp(10, 800);
        if (newZoomLevel != _zoomLevel) {
          setState(() {
            _zoomLevel = newZoomLevel;
          });
        }
      } else {
        // Reset to default zoom level when controller is not ready
        if (_zoomLevel != 100) {
          setState(() {
            _zoomLevel = 100;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Build areas once with builders; keep these instances stable.
    _viewModel = ref.read(pdfViewModelProvider.notifier);

    // Add listener to update zoom level when controller zoom changes
    _viewModel.controller.addListener(_onControllerChanged);

    _areas = [
      Area(
        size: _lastPagesWidth,
        min: _pagesMin,
        max: _pagesMax,
        builder:
            (context, area) => Offstage(
              offstage:
                  !(ResponsiveBreakpoints.of(context).largerThan(MOBILE) &&
                      _showPagesSidebar),
              child: Consumer(
                builder: (context, ref, child) {
                  final pdfViewModel = ref.watch(pdfViewModelProvider);
                  final pdf = pdfViewModel.document;

                  final documentRef =
                      pdf.loaded && pdf.pickedPdfBytes != null
                          ? PdfDocumentRefData(
                            pdf.pickedPdfBytes!,
                            sourceName: 'document.pdf',
                          )
                          : null;

                  return PagesSidebar(
                    documentRef: documentRef,
                    controller: _viewModel.controller,
                    currentPage: _viewModel.currentPage,
                  );
                },
              ),
            ),
      ),
      Area(
        flex: 1,
        builder:
            (context, area) => RepaintBoundary(
              child: PdfPageArea(
                controller: _viewModel.controller,
                key: const ValueKey('pdf_page_area'),
                pageSize: _pageSize,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect breakpoint changes from Responsive Framework and update areas once.
    bool canShowPagesSidebar = true;
    try {
      canShowPagesSidebar = ResponsiveBreakpoints.of(
        context,
      ).largerThan(MOBILE);
    } catch (_) {
      canShowPagesSidebar = true;
    }
    if (_lastCanShowPagesSidebar != canShowPagesSidebar) {
      _lastCanShowPagesSidebar = canShowPagesSidebar;
      _applySidebarVisibility();
    }
  }

  @override
  void dispose() {
    _viewModel.controller.removeListener(_onControllerChanged);
    _splitController.dispose();
    super.dispose();
  }

  void _applySidebarVisibility() {
    // Respect responsive layout: disable Pages sidebar on MOBILE.
    bool canShowPagesSidebar = true;
    try {
      canShowPagesSidebar = ResponsiveBreakpoints.of(
        context,
      ).largerThan(MOBILE);
    } catch (_) {
      // If ResponsiveBreakpoints isn't available yet (e.g., during early init),
      // fall back to allowing sidebars to avoid crashes; builders also guard.
      canShowPagesSidebar = true;
    }

    // Left pages sidebar
    final left = _splitController.areas[0];
    final wantPagesVisible = _showPagesSidebar && canShowPagesSidebar;
    final isPagesHidden =
        (left.max == 1 && left.min == 0 && (left.size ?? 1) == 1);
    if (wantPagesVisible) {
      // Only expand if currently hidden; otherwise keep user's size.
      if (isPagesHidden) {
        left.max = _pagesMax;
        left.min = _pagesMin;
        left.size = _lastPagesWidth.clamp(_pagesMin, _pagesMax);
      } else {
        left.max = _pagesMax;
        left.min = _pagesMin;
        // Preserve current size (user may have adjusted it).
        _lastPagesWidth = left.size ?? _lastPagesWidth;
      }
    } else {
      // Only collapse if currently visible; remember current size for restore.
      if (!isPagesHidden) {
        _lastPagesWidth = left.size ?? _lastPagesWidth;
        left.min = 0;
        left.max = 1;
        left.size = 1; // effectively hidden
      }
    }
    // Right signatures sidebar
    final right = _splitController.areas[2];
    final isSignaturesHidden =
        (right.max == 1 && right.min == 0 && (right.size ?? 1) == 1);
    if (_showSignaturesSidebar) {
      if (isSignaturesHidden) {
        right.max = _signaturesMax;
        right.min = _signaturesMin;
        right.size = _lastSignaturesWidth.clamp(_signaturesMin, _signaturesMax);
      } else {
        right.max = _signaturesMax;
        right.min = _signaturesMin;
        _lastSignaturesWidth = right.size ?? _lastSignaturesWidth;
      }
    } else {
      if (!isSignaturesHidden) {
        _lastSignaturesWidth = right.size ?? _lastSignaturesWidth;
        right.min = 0;
        right.max = 1;
        right.size = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final isExporting = ref.watch(pdfExportViewModelProvider).exporting;
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
                  onClosePdf: _closePdf,
                  onJumpToPage: _jumpToPage,
                  onZoomOut: () {
                    if (_viewModel.controller.isReady) {
                      _viewModel.controller.zoomDown();
                      // Update display zoom level after controller zoom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _zoomLevel = (_viewModel.controller.currentZoom *
                                    100)
                                .round()
                                .clamp(10, 800);
                          });
                        }
                      });
                    }
                  },
                  onZoomIn: () {
                    if (_viewModel.controller.isReady) {
                      _viewModel.controller.zoomUp();
                      // Update display zoom level after controller zoom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _zoomLevel = (_viewModel.controller.currentZoom *
                                    100)
                                .round()
                                .clamp(10, 800);
                          });
                        }
                      });
                    }
                  },
                  zoomLevel: _zoomLevel,
                  filePath: widget.currentFile.path,
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
                // Expose a compact signature drawer trigger area for tests when sidebar hidden
                if (!_showSignaturesSidebar)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height:
                          0, // zero-height container exposing buttons offstage
                      width: 0,
                      child: Offstage(
                        offstage: true,
                        child: SignaturesSidebar(
                          onLoadSignatureFromFile: _loadSignatureFromFile,
                          onOpenDrawCanvas: _openDrawCanvas,
                          onSave: _saveSignedPdf,
                        ),
                      ),
                    ),
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
