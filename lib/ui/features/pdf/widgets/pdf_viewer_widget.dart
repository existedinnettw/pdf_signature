import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'pdf_page_overlays.dart';
import './pdf_mock_continuous_list.dart';
import '../view_model/pdf_view_model.dart';
import 'package:pdf_signature/domain/models/document.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'dart:typed_data';

// Provider to control whether viewer overlays (like scroll thumbs) are enabled.
// Integration tests can override this to false to avoid long-running animations.
final viewerOverlaysEnabledProvider = Provider<bool>((ref) => true);

class PdfViewerWidget extends ConsumerStatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.pageSize,
    this.pageKeyBuilder,
    this.scrollToPage,
    required this.controller,
    this.innerViewerKey,
    this.onDocumentChanged,
  });

  final Size pageSize;
  final GlobalKey Function(int page)? pageKeyBuilder;
  final void Function(int page)? scrollToPage;
  final PdfViewerController controller;
  // Optional key applied to the inner Pdfrx PdfViewer to force disposal/rebuild
  final Key? innerViewerKey;
  // External hook to observe document changes (forwarded from Pdfrx onDocumentChanged)
  final void Function(PdfDocument?)? onDocumentChanged;

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  final ValueNotifier<PdfDocumentRef?> _docRefNotifier = ValueNotifier(null);
  Uint8List? _lastBytes;
  void _updateDocRef(Document doc) {
    if (!doc.loaded || doc.pickedPdfBytes == null) {
      if (_docRefNotifier.value != null) {
        debugPrint('[PdfViewerWidget] Clearing docRef (no document loaded)');
        _docRefNotifier.value = null;
      }
      return;
    }
    final bytes = doc.pickedPdfBytes!;
    if (!identical(bytes, _lastBytes)) {
      _lastBytes = bytes;
      final viewModel = ref.read(pdfViewModelProvider.notifier);
      // Update document version outside of build
      Future.microtask(() {
        viewModel.updateDocumentVersionIfNeeded();
      });
      debugPrint(
        '[PdfViewerWidget] New PDF bytes detected -> ${viewModel.documentSourceName}',
      );
      // Force a full detach by setting null first so PdfViewer unmounts even if the
      // framework would otherwise optimize rebuilds with same key ordering.
      if (_docRefNotifier.value != null) {
        _docRefNotifier.value = null;
      }
      final newRef = PdfDocumentRefData(
        bytes,
        sourceName: viewModel.documentSourceName,
      );
      _docRefNotifier.value = newRef;
    }
  }

  // Public getter for testing the actual viewer page
  int? get viewerCurrentPage => widget.controller.pageNumber;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // PdfViewerController doesn't have dispose method
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdfViewState = ref.watch(pdfViewModelProvider);
    final document = ref.watch(documentRepositoryProvider);
    final useMock = pdfViewState.useMockViewer;
    _updateDocRef(document);

    if (useMock) {
      return PdfMockContinuousList(
        pageSize: widget.pageSize,
        count: document.pageCount,
        pageKeyBuilder:
            widget.pageKeyBuilder ??
            (page) => GlobalKey(debugLabel: 'page_$page'),
        scrollToPage: widget.scrollToPage ?? (page) {},
      );
    }

    final overlaysEnabled = ref.watch(viewerOverlaysEnabledProvider);
    return ValueListenableBuilder<PdfDocumentRef?>(
      valueListenable: _docRefNotifier,
      builder: (context, docRef, _) {
        if (docRef == null) {
          String text;
          try {
            text = AppLocalizations.of(context).noPdfLoaded;
          } catch (_) {
            text = 'No PDF loaded';
          }
          return Center(child: Text(text));
        }
        final pdfViewModel = ref.read(pdfViewModelProvider.notifier);
        final viewerKey =
            widget.innerViewerKey ??
            Key('pdf_viewer_${pdfViewModel.documentSourceName}');

        return PdfViewer(
          docRef,
          key: viewerKey,
          controller: widget.controller,
          params: PdfViewerParams(
            onViewerReady: (document, controller) {
              // Update page count in repository
              ref
                  .read(pdfViewModelProvider.notifier)
                  .setPageCount(document.pages.length);
            },
            onPageChanged: (page) {
              if (page != null) {
                // Also update the view model to keep them in sync
                ref.read(pdfViewModelProvider.notifier).jumpToPage(page);
              }
            },
            onDocumentChanged: (doc) async {
              final pc = doc?.pages.length;
              debugPrint(
                '[PdfViewerWidget] onDocumentChanged called (pages=$pc)',
              );
              if (doc != null) {
                // Update internal page count state
                ref
                    .read(pdfViewModelProvider.notifier)
                    .setPageCount(doc.pages.length);
              }
              // Invoke external listener after internal handling
              try {
                widget.onDocumentChanged?.call(doc);
              } catch (e, st) {
                debugPrint(
                  '[PdfViewerWidget] external onDocumentChanged threw: $e\n$st',
                );
              }
            },
            viewerOverlayBuilder:
                overlaysEnabled
                    ? (context, size, handle) {
                      return [
                        // Vertical scroll thumb on the right
                        PdfViewerScrollThumb(
                          controller: widget.controller,
                          orientation: ScrollbarOrientation.right,
                          thumbSize: const Size(40, 25),
                          thumbBuilder:
                              (context, thumbSize, pageNumber, controller) =>
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    child: Center(
                                      child: Text(
                                        'Pg $pageNumber',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                        ),
                        // Horizontal scroll thumb on the bottom
                        PdfViewerScrollThumb(
                          controller: widget.controller,
                          orientation: ScrollbarOrientation.bottom,
                          thumbSize: const Size(40, 25),
                          thumbBuilder:
                              (context, thumbSize, pageNumber, controller) =>
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    child: Center(
                                      child: Text(
                                        'Pg $pageNumber',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                        ),
                      ];
                    }
                    : (context, size, handle) => const <Widget>[],
            // Per-page overlays to enable page-specific drag targets and placed signatures
            pageOverlaysBuilder: (context, pageRect, page) {
              return [
                PdfPageOverlays(
                  pageSize: Size(pageRect.width, pageRect.height),
                  pageNumber: page.pageNumber,
                ),
              ];
            },
          ),
        );
      },
    );
  }
}
