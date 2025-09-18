import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

import '../../../../domain/models/model.dart';
import 'signature_overlay.dart';
import '../../signature/widgets/signature_drag_data.dart';
import '../../signature/view_model/dragging_signature_view_model.dart';

/// Builds all overlays for a given page: placed signatures and the active one.
class PdfPageOverlays extends ConsumerWidget {
  const PdfPageOverlays({
    super.key,
    required this.pageSize,
    required this.pageNumber,
    this.onDragSignature,
    this.onResizeSignature,
    this.onConfirmSignature,
    this.onClearActiveOverlay,
    this.onSelectPlaced,
  });

  final Size pageSize;
  final int pageNumber;
  final ValueChanged<Offset>? onDragSignature;
  final ValueChanged<Offset>? onResizeSignature;
  final VoidCallback? onConfirmSignature;
  final VoidCallback? onClearActiveOverlay;
  final ValueChanged<int?>? onSelectPlaced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfViewModel = ref.watch(pdfViewModelProvider);
    // Subscribe to document changes to rebuild overlays
    final pdf = ref.watch(documentRepositoryProvider);
    final placed =
        pdf.placementsByPage[pageNumber] ?? const <SignaturePlacement>[];
    final activeRect = pdfViewModel.activeRect;
    final widgets = <Widget>[];

    // Base DragTarget filling the whole page to accept drops from signature cards.
    widgets.add(
      // Use a Positioned.fill inside a LayoutBuilder to compute normalized coordinates.
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDragging = ref.watch(isDraggingSignatureViewModelProvider);
            // Only activate DragTarget hit tests while dragging to preserve wheel scrolling.
            final target = DragTarget<SignatureDragData>(
              onAcceptWithDetails: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.offset);
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                if (w <= 0 || h <= 0) return;
                final nx = (local.dx / w).clamp(0.0, 1.0);
                final ny = (local.dy / h).clamp(0.0, 1.0);
                // Default size of the placed signature in normalized units
                const defW = 0.2;
                const defH = 0.1;
                final left = (nx - defW / 2).clamp(0.0, 1.0 - defW);
                final top = (ny - defH / 2).clamp(0.0, 1.0 - defH);
                final rect = Rect.fromLTWH(left, top, defW, defH);

                final d = details.data;
                ref
                    .read(pdfViewModelProvider.notifier)
                    .addPlacement(
                      page: pageNumber,
                      rect: rect,
                      asset: d.card?.asset,
                      rotationDeg: d.card?.rotationDeg ?? 0.0,
                      graphicAdjust: d.card?.graphicAdjust,
                    );
              },
              builder: (context, candidateData, rejectedData) {
                // Visual hint when hovering a draggable over the page.
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        candidateData.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.12)
                            : Colors.transparent,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            );
            return IgnorePointer(ignoring: !isDragging, child: target);
          },
        ),
      ),
    );

    for (int i = 0; i < placed.length; i++) {
      // Stored as UI-space rects (SignatureCardStateNotifier.pageSize).
      final p = placed[i];
      final uiRect = p.rect;
      widgets.add(
        SignatureOverlay(
          pageSize: pageSize,
          rect: uiRect,
          placement: p,
          placedIndex: i,
          pageNumber: pageNumber,
        ),
      );
    }

    // TODO:Add active overlay if present and not using mock (mock has its own)

    final useMock = pdfViewModel.useMockViewer;
    if (!useMock &&
        activeRect != null &&
        pageNumber == pdfViewModel.currentPage) {
      widgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final left = activeRect.left * constraints.maxWidth;
            final top = activeRect.top * constraints.maxHeight;
            final width = activeRect.width * constraints.maxWidth;
            final height = activeRect.height * constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: GestureDetector(
                    key: const Key('signature_overlay'),
                    // Removed onPanUpdate to allow scrolling
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Stack(children: widgets);
  }
}
