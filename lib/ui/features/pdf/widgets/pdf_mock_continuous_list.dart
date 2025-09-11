import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import 'pdf_page_overlays.dart';
import 'pdf_providers.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
// using only adjusted overlay, no direct model imports needed
import '../../signature/widgets/signature_drag_data.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

/// Mocked continuous viewer for tests or platforms without real viewer.
@visibleForTesting
class PdfMockContinuousList extends ConsumerStatefulWidget {
  const PdfMockContinuousList({
    super.key,
    required this.pageSize,
    required this.count,
    required this.pageKeyBuilder,
    required this.scrollToPage,
    this.onDragSignature,
    this.onResizeSignature,
    this.onConfirmSignature,
    this.onClearActiveOverlay,
    this.onSelectPlaced,
    this.pendingPage,
    this.clearPending,
  });

  final Size pageSize;
  final int count;
  final GlobalKey Function(int page) pageKeyBuilder;
  final void Function(int page) scrollToPage;
  final int? pendingPage;
  final VoidCallback? clearPending;

  final ValueChanged<Offset>? onDragSignature;
  final ValueChanged<Offset>? onResizeSignature;
  final VoidCallback? onConfirmSignature;
  final VoidCallback? onClearActiveOverlay;
  final ValueChanged<int?>? onSelectPlaced;

  @override
  ConsumerState<PdfMockContinuousList> createState() =>
      _PdfMockContinuousListState();
}

class _PdfMockContinuousListState extends ConsumerState<PdfMockContinuousList> {
  Rect _activeRect = const Rect.fromLTWH(0.2, 0.2, 0.3, 0.15); // normalized

  @override
  Widget build(BuildContext context) {
    final pageSize = widget.pageSize;
    final count = widget.count;
    final pageKeyBuilder = widget.pageKeyBuilder;
    final pendingPage = widget.pendingPage;
    final scrollToPage = widget.scrollToPage;
    final clearPending = widget.clearPending;
    final visible = ref.watch(signatureVisibilityProvider);
    final assets = ref.watch(signatureAssetRepositoryProvider);
    final aspectLocked = ref.watch(aspectLockedProvider);
    if (pendingPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = pendingPage;
        clearPending?.call();
        scheduleMicrotask(() => scrollToPage(p));
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
              key: pageKeyBuilder(pageNum),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AspectRatio(
                aspectRatio: pageSize.width / pageSize.height,
                child: Stack(
                  key: ValueKey('page_stack_$pageNum'),
                  children: [
                    DragTarget<SignatureDragData>(
                      onAcceptWithDetails: (details) {
                        final dragData = details.data;
                        final offset = details.offset;
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final localPosition = renderBox.globalToLocal(offset);
                          final normalizedX =
                              localPosition.dx / renderBox.size.width;
                          final normalizedY =
                              localPosition.dy / renderBox.size.height;

                          // Create a default rect for the signature (can be adjusted later)
                          final rect = Rect.fromLTWH(
                            (normalizedX - 0.1).clamp(
                              0.0,
                              0.8,
                            ), // Center horizontally with some margin
                            (normalizedY - 0.05).clamp(
                              0.0,
                              0.9,
                            ), // Center vertically with some margin
                            0.2, // Default width
                            0.1, // Default height
                          );

                          // Add placement to the document
                          ref
                              .read(documentRepositoryProvider.notifier)
                              .addPlacement(
                                page: pageNum,
                                rect: rect,
                                asset: dragData.card?.asset,
                                rotationDeg: dragData.card?.rotationDeg ?? 0.0,
                              );
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          color:
                              candidateData.isNotEmpty
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.grey.shade200,
                          child: Center(
                            child: Builder(
                              builder: (ctx) {
                                String label;
                                try {
                                  label = AppLocalizations.of(
                                    ctx,
                                  ).pageInfo(pageNum, count);
                                } catch (_) {
                                  label = 'Page $pageNum of $count';
                                }
                                return Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.black54,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    visible
                        ? Stack(
                          children: [
                            PdfPageOverlays(
                              pageSize: pageSize,
                              pageNumber: pageNum,
                              onDragSignature: widget.onDragSignature,
                              onResizeSignature: widget.onResizeSignature,
                              onConfirmSignature: widget.onConfirmSignature,
                              onClearActiveOverlay: widget.onClearActiveOverlay,
                              onSelectPlaced: widget.onSelectPlaced,
                            ),
                            // For tests expecting an active overlay, draw a mock
                            // overlay on page 1 when library has at least one asset
                            if (pageNum == 1 && assets.isNotEmpty)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final left =
                                      _activeRect.left * constraints.maxWidth;
                                  final top =
                                      _activeRect.top * constraints.maxHeight;
                                  final width =
                                      _activeRect.width * constraints.maxWidth;
                                  final height =
                                      _activeRect.height *
                                      constraints.maxHeight;
                                  // Publish rect for tests/other UI to observe
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!mounted) return;
                                    ref
                                        .read(activeRectProvider.notifier)
                                        .state = _activeRect;
                                  });
                                  return Stack(
                                    children: [
                                      Positioned(
                                        left: left,
                                        top: top,
                                        width: width,
                                        height: height,
                                        child: GestureDetector(
                                          key: const Key('signature_overlay'),
                                          onPanUpdate: (d) {
                                            final dx =
                                                d.delta.dx /
                                                constraints.maxWidth;
                                            final dy =
                                                d.delta.dy /
                                                constraints.maxHeight;
                                            setState(() {
                                              double l = (_activeRect.left + dx)
                                                  .clamp(0.0, 1.0);
                                              double t = (_activeRect.top + dy)
                                                  .clamp(0.0, 1.0);
                                              // clamp so it stays within page
                                              l = l.clamp(
                                                0.0,
                                                1.0 - _activeRect.width,
                                              );
                                              t = t.clamp(
                                                0.0,
                                                1.0 - _activeRect.height,
                                              );
                                              _activeRect = Rect.fromLTWH(
                                                l,
                                                t,
                                                _activeRect.width,
                                                _activeRect.height,
                                              );
                                            });
                                          },
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                      ),
                                      // resize handle bottom-right
                                      Positioned(
                                        left: left + width - 14,
                                        top: top + height - 14,
                                        width: 14,
                                        height: 14,
                                        child: GestureDetector(
                                          key: const Key('signature_handle'),
                                          onPanUpdate: (d) {
                                            final dx =
                                                d.delta.dx /
                                                constraints.maxWidth;
                                            final dy =
                                                d.delta.dy /
                                                constraints.maxHeight;
                                            setState(() {
                                              double newW = (_activeRect.width +
                                                      dx)
                                                  .clamp(0.05, 1.0);
                                              double newH =
                                                  (_activeRect.height + dy)
                                                      .clamp(0.05, 1.0);
                                              if (aspectLocked) {
                                                final ratio =
                                                    _activeRect.width /
                                                    _activeRect.height;
                                                // keep ratio; prefer width change driving height
                                                newH = (newW /
                                                        (ratio == 0
                                                            ? 1
                                                            : ratio))
                                                    .clamp(0.05, 1.0);
                                              }
                                              // clamp to page bounds
                                              newW = newW.clamp(
                                                0.05,
                                                1.0 - _activeRect.left,
                                              );
                                              newH = newH.clamp(
                                                0.05,
                                                1.0 - _activeRect.top,
                                              );
                                              _activeRect = Rect.fromLTWH(
                                                _activeRect.left,
                                                _activeRect.top,
                                                newW,
                                                newH,
                                              );
                                            });
                                          },
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
