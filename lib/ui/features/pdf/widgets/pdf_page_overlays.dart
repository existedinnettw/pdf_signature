import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/model.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'signature_overlay.dart';
import '../view_model/pdf_providers.dart';

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
    final pdf = ref.watch(documentRepositoryProvider);
    final placed =
        pdf.placementsByPage[pageNumber] ?? const <SignaturePlacement>[];
    final widgets = <Widget>[];

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
        ),
      );
    }

    // Add active overlay if present and not using mock (mock has its own)
    final activeRect = ref.watch(activeRectProvider);
    final useMock = ref.watch(useMockViewerProvider);
    if (!useMock && activeRect != null) {
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
