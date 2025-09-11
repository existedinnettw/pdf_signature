import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'pdf_page_overlays.dart';
import 'pdf_providers.dart';
import './pdf_mock_continuous_list.dart';
import '../../signature/widgets/signature_drag_data.dart';
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
  });

  final Size pageSize;
  final ValueChanged<Offset> onDragSignature;
  final ValueChanged<Offset> onResizeSignature;
  final VoidCallback onConfirmSignature;
  final VoidCallback onClearActiveOverlay;
  final ValueChanged<int?> onSelectPlaced;
  final GlobalKey Function(int page)? pageKeyBuilder;
  final void Function(int page)? scrollToPage;

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  PdfViewerController? _controller;
  PdfDocumentRef? _documentRef;

  // Public getter for testing the actual viewer page
  int? get viewerCurrentPage => _controller?.pageNumber;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
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
    final activeRect = ref.watch(activeRectProvider);
    final currentPage = ref.watch(pdfViewModelProvider);

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

    return Stack(
      children: [
        PdfViewer(
          _documentRef!,
          key: const Key(
            'pdf_continuous_mock_list',
          ), // Keep the same key for test compatibility
          controller: _controller,
          params: PdfViewerParams(
            onViewerReady: (document, controller) {
              // Update page count in repository
              ref
                  .read(documentRepositoryProvider.notifier)
                  .setPageCount(document.pages.length);
            },
            onPageChanged: (page) {
              // Update current page in view model
              if (page != null) {
                ref.read(pdfViewModelProvider.notifier).jumpToPage(page);
              }
            },
          ),
        ),
        // Drag target for dropping signatures
        Positioned.fill(
          child: DragTarget<SignatureDragData>(
            onAcceptWithDetails: (details) {
              final dragData = details.data;

              // For real PDF viewer, we need to calculate which page was dropped on
              // This is a simplified implementation - in a real app you'd need to
              // determine the exact page and position within that page
              final currentPage = ref.read(pdfViewModelProvider);

              // Create a default rect for the signature (can be adjusted later)
              final rect = const Rect.fromLTWH(0.1, 0.1, 0.2, 0.1);

              // Add placement to the document
              ref
                  .read(documentRepositoryProvider.notifier)
                  .addPlacement(
                    page: currentPage,
                    rect: rect,
                    asset: dragData.card?.asset,
                    rotationDeg: dragData.card?.rotationDeg ?? 0.0,
                    graphicAdjust: dragData.card?.graphicAdjust,
                  );
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                color:
                    candidateData.isNotEmpty
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
              );
            },
          ),
        ),
        // Add signature overlays on top
        Positioned.fill(
          child: Consumer(
            builder: (context, ref, _) {
              final visible = ref.watch(signatureVisibilityProvider);
              if (!visible) return const SizedBox.shrink();

              // For now, just add a simple overlay for the first page
              // This is a simplified version - in a real implementation you'd need
              // to handle overlays for each page properly
              return PdfPageOverlays(
                pageSize: widget.pageSize,
                pageNumber: ref.watch(pdfViewModelProvider),
                onDragSignature: widget.onDragSignature,
                onResizeSignature: widget.onResizeSignature,
                onConfirmSignature: widget.onConfirmSignature,
                onClearActiveOverlay: widget.onClearActiveOverlay,
                onSelectPlaced: widget.onSelectPlaced,
              );
            },
          ),
        ),
      ],
    );
  }
}
