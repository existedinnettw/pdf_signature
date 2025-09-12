import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
// Real viewer removed in migration; mock continuous list is used in tests.

import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'pdf_viewer_widget.dart';
import '../view_model/pdf_view_model.dart';
import 'pdf_providers.dart';

class PdfPageArea extends ConsumerStatefulWidget {
  const PdfPageArea({
    super.key,
    required this.pageSize,
    required this.onDragSignature,
    required this.onResizeSignature,
    required this.onConfirmSignature,
    required this.onClearActiveOverlay,
    required this.onSelectPlaced,
  });

  final Size pageSize;
  // viewerController removed in migration
  final ValueChanged<Offset> onDragSignature;
  final ValueChanged<Offset> onResizeSignature;
  final VoidCallback onConfirmSignature;
  final VoidCallback onClearActiveOverlay;
  final ValueChanged<int?> onSelectPlaced;
  @override
  ConsumerState<PdfPageArea> createState() => _PdfPageAreaState();
}

class _PdfPageAreaState extends ConsumerState<PdfPageArea> {
  final Map<int, GlobalKey> _pageKeys = {};
  // Real viewer controller removed; keep placeholder for API compatibility
  // ignore: unused_field
  late final Object _viewerController = Object();
  // Guards to avoid scroll feedback between provider and viewer
  int? _programmaticTargetPage;
  bool _suppressProviderListen = false;
  int? _visiblePage; // last page reported by viewer
  int? _pendingPage; // pending target for mock ensureVisible retry
  int _scrollRetryCount = 0;
  static const int _maxScrollRetries = 50;
  @override
  void initState() {
    super.initState();
    // If app starts in continuous mode with a loaded PDF, ensure the viewer
    // is instructed to align to the provider's current page once ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // initial scroll not needed; controller handles positioning
    });
  }

  // No dispose required for PdfViewerController (managed by owner if any)

  GlobalKey _pageKey(int page) => _pageKeys.putIfAbsent(
    page,
    () => GlobalKey(debugLabel: 'cont_page_$page'),
  );

  void _scrollToPage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _programmaticTargetPage = page;
      // Mock continuous: try ensureVisible on the page container
      // Mock continuous: try ensureVisible on the page container
      final ctx = _pageKey(page).currentContext;
      if (ctx != null) {
        try {
          final scrollable = Scrollable.of(ctx);
          final position = scrollable.position;
          final targetBox = ctx.findRenderObject() as RenderBox?;
          final scrollBox = scrollable.context.findRenderObject() as RenderBox?;
          if (targetBox != null && scrollBox != null) {
            final offsetInViewport = targetBox.localToGlobal(
              Offset.zero,
              ancestor: scrollBox,
            );
            final desiredTop = scrollBox.size.height * 0.1;
            final newPixels =
                (position.pixels + offsetInViewport.dy - desiredTop)
                    .clamp(position.minScrollExtent, position.maxScrollExtent)
                    .toDouble();
            position.jumpTo(newPixels);
            _visiblePage = page;
            _programmaticTargetPage = null;
            return;
          }
        } catch (_) {
          // Fallback to ensureVisible if any calculation fails
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.1,
            duration: Duration.zero,
            curve: Curves.linear,
          );
          _visiblePage = page;
          _programmaticTargetPage = null;
          return;
        }
        return;
      }
      _pendingPage = page;
      if (_scrollRetryCount < _maxScrollRetries) {
        _scrollRetryCount += 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final p = _pendingPage;
          if (p == null) return;
          _scrollToPage(p);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdf = ref.watch(documentRepositoryProvider);
    const pageViewMode = 'continuous';
    // React to PdfViewModel (source of truth for current page)
    ref.listen<int>(pdfViewModelProvider, (prev, next) {
      if (prev != next) {
        _scrollToPage(next);
      }
    });

    // React to provider currentPage changes (e.g., user tapped overview)
    ref.listen(currentPageProvider, (prev, next) {
      if (_suppressProviderListen) return;
      if (prev != next) {
        final target = next;
        // If we're already navigating to this target, ignore; otherwise allow new target.
        if (_programmaticTargetPage != null &&
            _programmaticTargetPage == target) {
          return;
        }
        // Only navigate if target differs from what viewer shows
        if (_visiblePage != target) {
          _scrollToPage(target);
        }
      }
    });
    // No page view mode switching; always continuous.

    if (!pdf.loaded) {
      // In tests, AppLocalizations delegate may not be injected; fallback.
      String text;
      try {
        text = AppLocalizations.of(context).noPdfLoaded;
      } catch (_) {
        text = 'No PDF loaded';
      }
      return Center(child: Text(text));
    }

    final isContinuous = pageViewMode == 'continuous';

    // Use real PDF viewer
    if (isContinuous) {
      return PdfViewerWidget(
        pageSize: widget.pageSize,
        onDragSignature: widget.onDragSignature,
        onResizeSignature: widget.onResizeSignature,
        onConfirmSignature: widget.onConfirmSignature,
        onClearActiveOverlay: widget.onClearActiveOverlay,
        onSelectPlaced: widget.onSelectPlaced,
        pageKeyBuilder: _pageKey,
        scrollToPage: _scrollToPage,
      );
    }
    return const SizedBox.shrink();
  }
}

// Zoom controls removed with single-page mode; continuous viewer manages zoom.
