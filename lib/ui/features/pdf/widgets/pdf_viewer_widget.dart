import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'pdf_page_overlays.dart';
import './pdf_mock_continuous_list.dart';
import '../view_model/pdf_providers.dart';
import '../view_model/pdf_view_model.dart';

class PdfViewerWidget extends ConsumerStatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.pageSize,
    required this.onDragSignature,
    required this.onResizeSignature,
    required this.onConfirmSignature,
    required this.onClearActiveOverlay,
    required this.onSelectPlaced,
    this.pageKeyBuilder,
    this.scrollToPage,
    required this.controller,
  });

  final Size pageSize;
  final ValueChanged<Offset> onDragSignature;
  final ValueChanged<Offset> onResizeSignature;
  final VoidCallback onConfirmSignature;
  final VoidCallback onClearActiveOverlay;
  final ValueChanged<int?> onSelectPlaced;
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
    final document = ref.watch(documentRepositoryProvider);
    final useMock = ref.watch(useMockViewerProvider);
    ref.watch(activeRectProvider); // trigger rebuild when active rect changes
    // Watch to rebuild on page change
    ref.watch(currentPageProvider);

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
        onDragSignature: widget.onDragSignature,
        onResizeSignature: widget.onResizeSignature,
        onConfirmSignature: widget.onConfirmSignature,
        onClearActiveOverlay: widget.onClearActiveOverlay,
        onSelectPlaced: widget.onSelectPlaced,
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
              .read(documentRepositoryProvider.notifier)
              .setPageCount(document.pages.length);
        },
        onPageChanged: (page) {
          if (page != null) {
            ref.read(currentPageProvider.notifier).state = page;
            // Also update the view model to keep them in sync
            ref.read(pdfViewModelProvider.notifier).jumpToPage(page);
          }
        },
        viewerOverlayBuilder: (context, size, handle) {
          return [
            PdfPageOverlays(
              pageSize: widget.pageSize,
              pageNumber: ref.watch(currentPageProvider),
              onDragSignature: widget.onDragSignature,
              onResizeSignature: widget.onResizeSignature,
              onConfirmSignature: widget.onConfirmSignature,
              onClearActiveOverlay: widget.onClearActiveOverlay,
              onSelectPlaced: widget.onSelectPlaced,
            ),
          ];
        },
      ),
    );
  }
}
