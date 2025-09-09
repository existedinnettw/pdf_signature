import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../data/services/export_providers.dart';
import '../../signature/view_model/signature_controller.dart';
import '../view_model/pdf_controller.dart';
import '../../signature/widgets/signature_drag_data.dart';
import 'pdf_mock_continuous_list.dart';
import 'pdf_page_overlays.dart';

class PdfPageArea extends ConsumerStatefulWidget {
  const PdfPageArea({
    super.key,
    required this.pageSize,
    required this.onDragSignature,
    required this.onResizeSignature,
    required this.onConfirmSignature,
    required this.onClearActiveOverlay,
    required this.onSelectPlaced,
    this.viewerController,
  });

  final Size pageSize;
  final PdfViewerController? viewerController;
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
  late final PdfViewerController _viewerController =
      widget.viewerController ?? PdfViewerController();
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
      final pdf = ref.read(pdfProvider);
      if (pdf.pickedPdfPath != null && pdf.loaded) {
        _scrollToPage(pdf.currentPage);
      }
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
      final pdf = ref.read(pdfProvider);
      const isContinuous = true;

      // Real continuous: drive via PdfViewerController
      if (pdf.pickedPdfPath != null && isContinuous) {
        if (_viewerController.isReady) {
          _programmaticTargetPage = page;
          // print("[DEBUG] viewerController Scrolling to page $page");
          _viewerController.goToPage(
            pageNumber: page,
            anchor: PdfPageAnchor.top,
          );
          // Fallback: if no onPageChanged arrives (e.g., same page), don't block future jumps
          // Use post-frame callbacks to avoid scheduling timers in tests.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_programmaticTargetPage == page) {
                _programmaticTargetPage = null;
              }
            });
          });
          _pendingPage = null;
          _scrollRetryCount = 0;
        } else {
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
        }
        return;
      }
      // print("[DEBUG] Mock Scrolling to page $page");
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
    final pdf = ref.watch(pdfProvider);
    const pageViewMode = 'continuous';

    // React to provider currentPage changes (e.g., user tapped overview)
    ref.listen(pdfProvider, (prev, next) {
      if (_suppressProviderListen) return;
      if ((prev?.currentPage != next.currentPage)) {
        final target = next.currentPage;
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

    final useMock = ref.watch(useMockViewerProvider);
    final isContinuous = pageViewMode == 'continuous';

    // Mock continuous: ListView with prebuilt children, no controller
    if (useMock && isContinuous) {
      final count = pdf.pageCount > 0 ? pdf.pageCount : 1;
      return PdfMockContinuousList(
        pageSize: widget.pageSize,
        count: count,
        pageKeyBuilder: _pageKey,
        scrollToPage: _scrollToPage,
        pendingPage: _pendingPage,
        clearPending: () {
          _pendingPage = null;
          _scrollRetryCount = 0;
        },
        onDragSignature: (delta) => widget.onDragSignature(delta),
        onResizeSignature: (delta) => widget.onResizeSignature(delta),
        onConfirmSignature: widget.onConfirmSignature,
        onClearActiveOverlay: widget.onClearActiveOverlay,
        onSelectPlaced: widget.onSelectPlaced,
      );
    }

    // Real continuous mode (pdfrx): copy example patterns
    // https://github.com/espresso3389/pdfrx/blob/2cc32c1e2aa2a054602d20a5e7cf60bcc2d6a889/packages/pdfrx/example/viewer/lib/main.dart
    if (pdf.pickedPdfPath != null && isContinuous) {
      final viewer = PdfViewer.file(
        pdf.pickedPdfPath!,
        controller: _viewerController,
        params: PdfViewerParams(
          pageAnchor: PdfPageAnchor.top,
          keyHandlerParams: PdfViewerKeyHandlerParams(autofocus: true),
          maxScale: 8,
          scrollByMouseWheel: 0.6,
          // Render signature overlays on each page via pdfrx pageOverlaysBuilder
          pageOverlaysBuilder: (context, pageRect, page) {
            return [
              Consumer(
                builder: (context, ref, _) {
                  final visible = ref.watch(signatureVisibilityProvider);
                  if (!visible) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: pageRect.width,
                      height: pageRect.height,
                      child: PdfPageOverlays(
                        pageSize: widget.pageSize,
                        pageNumber: page.pageNumber,
                        onDragSignature:
                            (delta) => widget.onDragSignature(delta),
                        onResizeSignature:
                            (delta) => widget.onResizeSignature(delta),
                        onConfirmSignature: widget.onConfirmSignature,
                        onClearActiveOverlay: widget.onClearActiveOverlay,
                        onSelectPlaced: widget.onSelectPlaced,
                      ),
                    ),
                  );
                },
              ),
            ];
          },
          // Add overlay scroll thumbs (vertical on right, horizontal on bottom)
          viewerOverlayBuilder:
              (context, size, handleLinkTap) => [
                PdfViewerScrollThumb(
                  controller: _viewerController,
                  orientation: ScrollbarOrientation.right,
                  thumbSize: const Size(40, 24),
                  thumbBuilder:
                      (context, thumbSize, pageNumber, controller) => Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Center(
                          child: Text(
                            pageNumber.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                ),
                PdfViewerScrollThumb(
                  controller: _viewerController,
                  orientation: ScrollbarOrientation.bottom,
                  thumbSize: const Size(40, 24),
                  thumbBuilder:
                      (context, thumbSize, pageNumber, controller) => Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Center(
                          child: Text(
                            pageNumber.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                ),
              ],
          onViewerReady: (doc, controller) {
            if (pdf.pageCount != doc.pages.length) {
              ref.read(pdfProvider.notifier).setPageCount(doc.pages.length);
            }
            final target = _pendingPage ?? pdf.currentPage;
            _pendingPage = null;
            _scrollRetryCount = 0;
            // Defer navigation to the next frame to ensure controller state is fully ready.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scrollToPage(target);
            });
          },
          onPageChanged: (n) {
            if (n == null) return;
            _visiblePage = n;
            // Programmatic navigation: wait until target reached
            if (_programmaticTargetPage != null) {
              if (n == _programmaticTargetPage) {
                if (n != ref.read(pdfProvider).currentPage) {
                  _suppressProviderListen = true;
                  ref.read(pdfProvider.notifier).jumpTo(n);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _suppressProviderListen = false;
                  });
                }
                _programmaticTargetPage = null;
              }
              return;
            }
            // User scroll -> reflect page to provider without re-triggering scroll
            if (n != ref.read(pdfProvider).currentPage) {
              _suppressProviderListen = true;
              ref.read(pdfProvider.notifier).jumpTo(n);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _suppressProviderListen = false;
              });
            }
          },
        ),
      );
      // Accept drops of signature card over the viewer
      final drop = DragTarget<Object>(
        onWillAcceptWithDetails: (details) => details.data is SignatureDragData,
        onAcceptWithDetails: (details) {
          // Map the local position to UI page coordinates of the visible page
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.offset);
          final size = box.size;
          // Assume drop targets the current visible page; compute relative center
          final cx = (local.dx / size.width) * widget.pageSize.width;
          final cy = (local.dy / size.height) * widget.pageSize.height;
          final data = details.data;
          if (data is SignatureDragData && data.asset != null) {
            // Set current overlay to use this asset
            ref
                .read(signatureProvider.notifier)
                .setImageFromLibrary(asset: data.asset!);
          }
          ref.read(signatureProvider.notifier).placeAtCenter(Offset(cx, cy));
          ref
              .read(pdfProvider.notifier)
              .setSignedPage(ref.read(pdfProvider).currentPage);
        },
        builder:
            (context, candidateData, rejected) => Stack(
              fit: StackFit.expand,
              children: [
                viewer,
                if (candidateData.isNotEmpty)
                  Container(color: Colors.blue.withValues(alpha: 0.08)),
              ],
            ),
      );
      return drop;
    }

    return const SizedBox.shrink();
  }
}

// Zoom controls removed with single-page mode; continuous viewer manages zoom.
