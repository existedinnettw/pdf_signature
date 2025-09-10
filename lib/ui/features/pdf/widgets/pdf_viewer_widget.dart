import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'pdf_page_overlays.dart';
import 'pdf_providers.dart';
import './pdf_mock_continuous_list.dart';

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
              // Update current page in repository
              if (page != null) {
                ref.read(documentRepositoryProvider.notifier).jumpTo(page);
              }
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
                pageNumber: document.currentPage,
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
