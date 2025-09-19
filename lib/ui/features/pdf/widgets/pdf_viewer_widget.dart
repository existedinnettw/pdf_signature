import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'pdf_page_overlays.dart';
import './pdf_mock_continuous_list.dart';
import '../view_model/pdf_view_model.dart';

class PdfViewerWidget extends ConsumerStatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.pageSize,
    this.pageKeyBuilder,
    this.scrollToPage,
    required this.controller,
  });

  final Size pageSize;
  final GlobalKey Function(int page)? pageKeyBuilder;
  final void Function(int page)? scrollToPage;
  final PdfViewerController controller;

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  PdfDocumentRef? _documentRef;

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
    final pdfViewModel = ref.watch(pdfViewModelProvider);
    final document = pdfViewModel.document;
    final useMock = pdfViewModel.useMockViewer;
    // trigger rebuild when active rect changes

    // Update document ref when document changes
    if (document.loaded && document.pickedPdfBytes != null) {
      if (_documentRef == null) {
        _documentRef = PdfDocumentRefData(
          document.pickedPdfBytes!,
          sourceName: 'document.pdf',
        );
      }
    } else {
      _documentRef = null;
    }

    if (_documentRef == null && !useMock) {
      String text;
      try {
        text = AppLocalizations.of(context).noPdfLoaded;
      } catch (_) {
        text = 'No PDF loaded';
      }
      return Center(child: Text(text));
    }

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

    return PdfViewer(
      _documentRef!,
      key: const Key(
        'pdf_continuous_mock_list',
      ), // Keep the same key for test compatibility
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
        viewerOverlayBuilder: (context, size, handle) {
          return [
            // Vertical scroll thumb on the right
            PdfViewerScrollThumb(
              controller: widget.controller,
              orientation: ScrollbarOrientation.right,
              thumbSize: const Size(40, 25),
              thumbBuilder:
                  (context, thumbSize, pageNumber, controller) => Container(
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
                  (context, thumbSize, pageNumber, controller) => Container(
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
        },
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
  }
}
