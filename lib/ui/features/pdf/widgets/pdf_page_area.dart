import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
// Real viewer removed in migration; mock continuous list is used in tests.

import 'pdf_viewer_widget.dart';
import 'package:pdfrx/pdfrx.dart';
import '../view_model/pdf_view_model.dart';
import '../view_model/pdf_export_view_model.dart';

class PdfPageArea extends ConsumerStatefulWidget {
  const PdfPageArea({
    super.key,
    required this.pageSize,
    required this.controller,
  });

  final Size pageSize;
  final PdfViewerController controller;
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
  int? _lastListenedPage;
  @override
  void initState() {
    super.initState();
    // If app starts in continuous mode with a loaded PDF, ensure the viewer
    // is instructed to align to the provider's current page once ready.
    // Do not schedule mock scroll sync in real viewer mode.
    // In mock mode, scrolling is driven on demand when currentPage changes.
  }

  // No dispose required for PdfViewerController (managed by owner if any)

  GlobalKey _pageKey(int page) => _pageKeys.putIfAbsent(
    page,
    () => GlobalKey(debugLabel: 'cont_page_$page'),
  );

  void _scrollToPage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only valid in mock viewer mode; skip otherwise
      final useMock = ref.read(pdfViewModelProvider).useMockViewer;
      if (!useMock) return;
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
    final pdfViewModel = ref.watch(pdfViewModelProvider);
    final pdf = pdfViewModel.document;
    const pageViewMode = 'continuous';
    // React to PdfViewModel currentPage changes. With ChangeNotifierProvider,
    // prev/next are the same instance, so compare to a local cache.
    ref.listen(pdfViewModelProvider, (prev, next) {
      // Only perform manual scrolling in mock viewer mode. In real viewer mode,
      // PdfViewerController + onPageChanged keep things in sync, and attempting
      // to scroll here (without mock page keys) creates repeated frame
      // callbacks that never find targets, leading to hangs.
      if (!next.useMockViewer) {
        return;
      }
      if (_suppressProviderListen) return;
      final target = next.currentPage;
      if (_lastListenedPage == target) return;
      _lastListenedPage = target;
      if (_programmaticTargetPage != null &&
          _programmaticTargetPage == target) {
        return;
      }
      if (_visiblePage != target) {
        _scrollToPage(target);
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
      // While exporting, fully detach the viewer to avoid background activity
      // and ensure a clean re-initialization afterward.
      final exporting = ref.watch(pdfExportViewModelProvider).exporting;
      if (exporting) {
        return const SizedBox.expand(key: Key('exporting_viewer_placeholder'));
      }
      return PdfViewerWidget(
        pageSize: widget.pageSize,
        pageKeyBuilder: _pageKey,
        scrollToPage: _scrollToPage,
        controller: widget.controller,
        innerViewerKey: const ValueKey('viewer_idle'),
      );
    }
    return const SizedBox.shrink();
  }
}

// Zoom controls removed with single-page mode; continuous viewer manages zoom.
