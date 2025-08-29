import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../data/services/providers.dart';
import '../../../../data/model/model.dart';
import '../view_model/view_model.dart';

class PdfPageArea extends ConsumerWidget {
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
  final ValueChanged<Offset> onDragSignature;
  final ValueChanged<Offset> onResizeSignature;
  final VoidCallback onConfirmSignature;
  final VoidCallback onClearActiveOverlay;
  final ValueChanged<int?> onSelectPlaced;

  Future<void> _showContextMenuForPlaced({
    required BuildContext context,
    required WidgetRef ref,
    required Offset globalPos,
    required int index,
  }) async {
    onSelectPlaced(index);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      items: [
        PopupMenuItem<String>(
          key: Key('ctx_delete_signature'),
          value: 'delete',
          child: Text(AppLocalizations.of(context).delete),
        ),
      ],
    );
    if (choice == 'delete') {
      final currentPage = ref.read(pdfProvider).currentPage;
      ref
          .read(pdfProvider.notifier)
          .removePlacement(page: currentPage, index: index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(pdfProvider);
    if (!pdf.loaded) {
      return Center(child: Text(AppLocalizations.of(context).noPdfLoaded));
    }
    final useMock = ref.watch(useMockViewerProvider);
    if (useMock) {
      return Center(
        child: AspectRatio(
          aspectRatio: pageSize.width / pageSize.height,
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
                    style: const TextStyle(fontSize: 24, color: Colors.black54),
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final sig = ref.watch(signatureProvider);
                  final visible = ref.watch(signatureVisibilityProvider);
                  return visible
                      ? _buildPageOverlays(context, ref, sig)
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
    }
    if (pdf.pickedPdfPath != null) {
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
                          ? _buildPageOverlays(context, ref, sig)
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPageOverlays(
    BuildContext context,
    WidgetRef ref,
    SignatureState sig,
  ) {
    final pdf = ref.watch(pdfProvider);
    final current = pdf.currentPage;
    final placed = pdf.placementsByPage[current] ?? const <Rect>[];
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
        ),
      );
    }
    if (sig.rect != null &&
        sig.editingEnabled &&
        (pdf.signedPage == null || pdf.signedPage == current)) {
      widgets.add(
        _buildSignatureOverlay(context, ref, sig, sig.rect!, interactive: true),
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
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / pageSize.width;
        final scaleY = constraints.maxHeight / pageSize.height;
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
                                  (d) => onResizeSignature(
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
                          (d) => onDragSignature(
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
                            onConfirmSignature();
                          } else if (choice == 'delete') {
                            onClearActiveOverlay();
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
                            onConfirmSignature();
                          } else if (choice == 'delete') {
                            onClearActiveOverlay();
                          }
                        });
                      },
                      child: content,
                    );
                  } else {
                    content = GestureDetector(
                      key: Key('placed_signature_${placedIndex ?? 'x'}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelectPlaced(placedIndex),
                      onSecondaryTapDown: (d) {
                        if (placedIndex != null) {
                          _showContextMenuForPlaced(
                            context: context,
                            ref: ref,
                            globalPos: d.globalPosition,
                            index: placedIndex,
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
