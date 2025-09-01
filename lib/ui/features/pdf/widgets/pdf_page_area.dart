import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../data/services/providers.dart';
import '../../../../data/model/model.dart';
import '../view_model/view_model.dart';
import '../../preferences/providers.dart';

class PdfPageArea extends ConsumerStatefulWidget {
  const PdfPageArea({
    super.key,
    required this.pageSize,
    this.controller,
    required this.onDragSignature,
    required this.onResizeSignature,
    required this.onConfirmSignature,
    required this.onClearActiveOverlay,
    required this.onSelectPlaced,
  });

  final Size pageSize;
  final TransformationController? controller;
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
  final PdfViewerController _viewerController = PdfViewerController();
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
      final mode = ref.read(pageViewModeProvider);
      final pdf = ref.read(pdfProvider);
      if (mode == 'continuous' && pdf.pickedPdfPath != null && pdf.loaded) {
        _scrollToPage(pdf.currentPage);
      }
    });
  }

  GlobalKey _pageKey(int page) => _pageKeys.putIfAbsent(
    page,
    () => GlobalKey(debugLabel: 'cont_page_$page'),
  );

  void _scrollToPage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pdf = ref.read(pdfProvider);
      final isContinuous = ref.read(pageViewModeProvider) == 'continuous';

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Future<void>.delayed(const Duration(milliseconds: 120), () {
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
            duration: const Duration(milliseconds: 1),
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
    final pageViewMode = ref.watch(pageViewModeProvider);

    // React to provider currentPage changes (e.g., user tapped overview)
    ref.listen(pdfProvider, (prev, next) {
      final mode = ref.read(pageViewModeProvider);
      if (_suppressProviderListen) return;
      if (mode == 'continuous' && (prev?.currentPage != next.currentPage)) {
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
    // When switching to continuous, bring current page into view
    ref.listen<String>(pageViewModeProvider, (prev, next) {
      if (next == 'continuous') {
        // Skip initial auto-scroll in mock mode to avoid fighting with
        // early provider-driven jumps during tests.
        final isMock = ref.read(useMockViewerProvider);
        if (isMock) return;
        final p = ref.read(pdfProvider).currentPage;
        if (_visiblePage != p) {
          _scrollToPage(p);
        }
      }
    });

    if (!pdf.loaded) {
      return Center(child: Text(AppLocalizations.of(context).noPdfLoaded));
    }

    final useMock = ref.watch(useMockViewerProvider);
    final isContinuous = pageViewMode == 'continuous';

    // Mock single-page
    if (useMock && !isContinuous) {
      return Center(
        child: AspectRatio(
          aspectRatio: widget.pageSize.width / widget.pageSize.height,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            panEnabled: false,
            transformationController: widget.controller,
            child: Stack(
              key: const Key('page_stack'),
              children: [
                Container(
                  key: ValueKey('pdf_page_view_${pdf.currentPage}'),
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).pageInfo(pdf.currentPage, pdf.pageCount),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final sig = ref.watch(signatureProvider);
                    final visible = ref.watch(signatureVisibilityProvider);
                    return visible
                        ? _buildPageOverlays(context, ref, sig, pdf.currentPage)
                        : const SizedBox.shrink();
                  },
                ),
                _ZoomControls(controller: widget.controller),
              ],
            ),
          ),
        ),
      );
    }

    // Mock continuous: ListView with prebuilt children, no controller
    if (useMock && isContinuous) {
      final count = pdf.pageCount > 0 ? pdf.pageCount : 1;
      return Builder(
        builder: (ctx) {
          // Defer processing of any pending jump until after the tree is mounted.
          if (_pendingPage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final p = _pendingPage;
              if (p != null) {
                _pendingPage = null;
                _scrollRetryCount = 0;
                Future<void>.delayed(const Duration(milliseconds: 1), () {
                  if (!mounted) return;
                  _scrollToPage(p);
                });
              }
            });
          }
          return SingleChildScrollView(
            key: const Key('pdf_continuous_mock_list'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: List.generate(count, (idx) {
                final pageNum = idx + 1;
                return Center(
                  child: Padding(
                    key: _pageKey(pageNum),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AspectRatio(
                      aspectRatio:
                          widget.pageSize.width / widget.pageSize.height,
                      child: Stack(
                        key: ValueKey('page_stack_$pageNum'),
                        children: [
                          Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).pageInfo(pageNum, count),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final sig = ref.watch(signatureProvider);
                              final visible = ref.watch(
                                signatureVisibilityProvider,
                              );
                              return visible
                                  ? _buildPageOverlays(
                                    context,
                                    ref,
                                    sig,
                                    pageNum,
                                  )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
    }

    // Real single-page mode
    if (pdf.pickedPdfPath != null && !isContinuous) {
      return PdfDocumentViewBuilder.file(
        pdf.pickedPdfPath!,
        builder: (context, document) {
          if (document == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final pages = document.pages;
          final pageNum = pdf.currentPage.clamp(1, pages.length);
          final page = pages[pageNum - 1];
          final aspect = page.width / page.height;
          if (pdf.pageCount != pages.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(pdfProvider.notifier).setPageCount(pages.length);
            });
          }
          return Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                panEnabled: false,
                transformationController: widget.controller,
                child: Stack(
                  key: const Key('page_stack'),
                  children: [
                    PdfPageView(
                      key: ValueKey('pdf_page_view_$pageNum'),
                      document: document,
                      pageNumber: pageNum,
                      alignment: Alignment.center,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final sig = ref.watch(signatureProvider);
                        final visible = ref.watch(signatureVisibilityProvider);
                        return visible
                            ? _buildPageOverlays(context, ref, sig, pageNum)
                            : const SizedBox.shrink();
                      },
                    ),
                    _ZoomControls(controller: widget.controller),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Real continuous mode (pdfrx): copy example patterns
    if (pdf.pickedPdfPath != null && isContinuous) {
      return PdfViewer.file(
        pdf.pickedPdfPath!,
        controller: _viewerController,
        params: PdfViewerParams(
          pageAnchor: PdfPageAnchor.top,
          onViewerReady: (doc, controller) {
            if (pdf.pageCount != doc.pages.length) {
              ref.read(pdfProvider.notifier).setPageCount(doc.pages.length);
            }
            final target = _pendingPage ?? pdf.currentPage;
            _pendingPage = null;
            _scrollRetryCount = 0;
            _programmaticTargetPage = target;
            controller.goToPage(pageNumber: target, anchor: PdfPageAnchor.top);
            // Fallback: if the viewer doesn't emit onPageChanged (e.g., already at target),
            // ensure we don't keep blocking provider-driven jumps.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Future<void>.delayed(const Duration(milliseconds: 120), () {
                if (!mounted) return;
                if (_programmaticTargetPage == target) {
                  _programmaticTargetPage = null;
                }
              });
            });
            // Also ensure a scroll attempt is queued in case current state suppressed earlier.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_visiblePage != ref.read(pdfProvider).currentPage) {
                _scrollToPage(ref.read(pdfProvider).currentPage);
              }
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
    }

    return const SizedBox.shrink();
  }

  // Context menu for already placed signatures
  void _showContextMenuForPlaced({
    required BuildContext context,
    required WidgetRef ref,
    required Offset globalPos,
    required int index,
    required int page,
  }) {
    final l = AppLocalizations.of(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      items: [
        PopupMenuItem<String>(
          key: const Key('ctx_placed_delete'),
          value: 'delete',
          child: Text(l.delete),
        ),
      ],
    ).then((choice) {
      switch (choice) {
        case 'delete':
          ref
              .read(pdfProvider.notifier)
              .removePlacement(page: page, index: index);
          break;
        default:
          break;
      }
    });
  }

  Widget _buildPageOverlays(
    BuildContext context,
    WidgetRef ref,
    SignatureState sig,
    int pageNumber,
  ) {
    final pdf = ref.watch(pdfProvider);
    final placed = pdf.placementsByPage[pageNumber] ?? const <Rect>[];
    final widgets = <Widget>[];
    for (int i = 0; i < placed.length; i++) {
      final r = placed[i];
      widgets.add(
        _buildSignatureOverlay(
          context,
          ref,
          sig,
          r,
          interactive: false,
          placedIndex: i,
          pageNumber: pageNumber,
        ),
      );
    }
    if (sig.rect != null &&
        sig.editingEnabled &&
        (pdf.signedPage == null || pdf.signedPage == pageNumber)) {
      widgets.add(
        _buildSignatureOverlay(
          context,
          ref,
          sig,
          sig.rect!,
          interactive: true,
          pageNumber: pageNumber,
        ),
      );
    }
    return Stack(children: widgets);
  }

  Widget _buildSignatureOverlay(
    BuildContext context,
    WidgetRef ref,
    SignatureState sig,
    Rect r, {
    bool interactive = true,
    int? placedIndex,
    required int pageNumber,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / widget.pageSize.width;
        final scaleY = constraints.maxHeight / widget.pageSize.height;
        final left = r.left * scaleX;
        final top = r.top * scaleY;
        final width = r.width * scaleX;
        final height = r.height * scaleY;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Builder(
                builder: (context) {
                  final selectedIdx =
                      ref.read(pdfProvider).selectedPlacementIndex;
                  final bool isPlaced = placedIndex != null;
                  final bool isSelected =
                      isPlaced && selectedIdx == placedIndex;
                  final Color borderColor =
                      isPlaced ? Colors.red : Colors.indigo;
                  final double borderWidth =
                      isPlaced ? (isSelected ? 3.0 : 2.0) : 2.0;
                  Widget content = DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        0,
                        0,
                        0,
                        0.05 + math.min(0.25, (sig.contrast - 1.0).abs()),
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final processed = ref.watch(
                              processedSignatureImageProvider,
                            );
                            final bytes = processed ?? sig.imageBytes;
                            if (bytes == null) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context).signature,
                                ),
                              );
                            }
                            return Image.memory(bytes, fit: BoxFit.contain);
                          },
                        ),
                        if (interactive)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              key: const Key('signature_handle'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate:
                                  (d) => widget.onResizeSignature(
                                    Offset(
                                      d.delta.dx / scaleX,
                                      d.delta.dy / scaleY,
                                    ),
                                  ),
                              child: const Icon(Icons.open_in_full, size: 20),
                            ),
                          ),
                      ],
                    ),
                  );
                  if (interactive && sig.editingEnabled) {
                    content = GestureDetector(
                      key: const Key('signature_overlay'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) {},
                      onPanUpdate:
                          (d) => widget.onDragSignature(
                            Offset(d.delta.dx / scaleX, d.delta.dy / scaleY),
                          ),
                      onSecondaryTapDown: (d) {
                        final pos = d.globalPosition;
                        showMenu<String>(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            pos.dx,
                            pos.dy,
                            pos.dx,
                            pos.dy,
                          ),
                          items: [
                            PopupMenuItem<String>(
                              key: Key('ctx_active_confirm'),
                              value: 'confirm',
                              child: Text(AppLocalizations.of(context).confirm),
                            ),
                            PopupMenuItem<String>(
                              key: Key('ctx_active_delete'),
                              value: 'delete',
                              child: Text(AppLocalizations.of(context).delete),
                            ),
                          ],
                        ).then((choice) {
                          if (choice == 'confirm') {
                            widget.onConfirmSignature();
                          } else if (choice == 'delete') {
                            widget.onClearActiveOverlay();
                          }
                        });
                      },
                      onLongPressStart: (d) {
                        final pos = d.globalPosition;
                        showMenu<String>(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            pos.dx,
                            pos.dy,
                            pos.dx,
                            pos.dy,
                          ),
                          items: [
                            PopupMenuItem<String>(
                              key: Key('ctx_active_confirm_lp'),
                              value: 'confirm',
                              child: Text(AppLocalizations.of(context).confirm),
                            ),
                            PopupMenuItem<String>(
                              key: Key('ctx_active_delete_lp'),
                              value: 'delete',
                              child: Text(AppLocalizations.of(context).delete),
                            ),
                          ],
                        ).then((choice) {
                          if (choice == 'confirm') {
                            widget.onConfirmSignature();
                          } else if (choice == 'delete') {
                            widget.onClearActiveOverlay();
                          }
                        });
                      },
                      child: content,
                    );
                  } else {
                    content = GestureDetector(
                      key: Key('placed_signature_${placedIndex ?? 'x'}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSelectPlaced(placedIndex),
                      onSecondaryTapDown: (d) {
                        if (placedIndex != null) {
                          _showContextMenuForPlaced(
                            context: context,
                            ref: ref,
                            globalPos: d.globalPosition,
                            index: placedIndex,
                            page: pageNumber,
                          );
                        }
                      },
                      onLongPressStart: (d) {
                        if (placedIndex != null) {
                          _showContextMenuForPlaced(
                            context: context,
                            ref: ref,
                            globalPos: d.globalPosition,
                            index: placedIndex,
                            page: pageNumber,
                          );
                        }
                      },
                      child: content,
                    );
                  }
                  return content;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({this.controller});
  final TransformationController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox.shrink();
    void setScale(double scale) {
      final m = controller!.value.clone();
      // Reset translation but keep center
      m.setEntry(0, 0, scale);
      m.setEntry(1, 1, scale);
      controller!.value = m;
    }

    return Positioned(
      right: 8,
      bottom: 8,
      child: Card(
        elevation: 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Zoom out',
              icon: const Icon(Icons.remove),
              onPressed: () {
                final current = controller!.value.getMaxScaleOnAxis();
                setScale((current - 0.1).clamp(0.5, 4.0));
              },
            ),
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: () => controller!.value = Matrix4.identity(),
            ),
            IconButton(
              tooltip: 'Zoom in',
              icon: const Icon(Icons.add),
              onPressed: () {
                final current = controller!.value.getMaxScaleOnAxis();
                setScale((current + 0.1).clamp(0.5, 4.0));
              },
            ),
          ],
        ),
      ),
    );
  }
}
