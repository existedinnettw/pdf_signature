import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/view_model.dart';
import 'signature_overlay.dart';

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
    final pdf = ref.watch(pdfProvider);
    final sig = ref.watch(signatureProvider);
    final placed = pdf.placementsByPage[pageNumber] ?? const <Rect>[];
    final widgets = <Widget>[];

    for (int i = 0; i < placed.length; i++) {
      final r = placed[i]; // stored as normalized 0..1 of page size
      final uiRect = Rect.fromLTWH(
        r.left * pageSize.width,
        r.top * pageSize.height,
        r.width * pageSize.width,
        r.height * pageSize.height,
      );
      widgets.add(
        SignatureOverlay(
          pageSize: pageSize,
          rect: uiRect,
          sig: sig,
          pageNumber: pageNumber,
          interactive: false,
          placedIndex: i,
          onSelectPlaced: onSelectPlaced,
        ),
      );
    }

    final showActive =
        sig.rect != null &&
        sig.editingEnabled &&
        (pdf.signedPage == null || pdf.signedPage == pageNumber) &&
        pdf.currentPage == pageNumber;

    if (showActive) {
      widgets.add(
        SignatureOverlay(
          pageSize: pageSize,
          rect: sig.rect!,
          sig: sig,
          pageNumber: pageNumber,
          interactive: true,
          onDragSignature: onDragSignature,
          onResizeSignature: onResizeSignature,
          onConfirmSignature: onConfirmSignature,
          onClearActiveOverlay: onClearActiveOverlay,
        ),
      );
    }

    return Stack(children: widgets);
  }
}
