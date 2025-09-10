import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import '../../../../domain/models/model.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
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
    final pdf = ref.watch(documentRepositoryProvider);
    final sig = ref.watch(signatureCardProvider);
    final placed =
        pdf.placementsByPage[pageNumber] ?? const <SignaturePlacement>[];
    final widgets = <Widget>[];

    for (int i = 0; i < placed.length; i++) {
      // Stored as UI-space rects (SignatureCardStateNotifier.pageSize).
      final uiRect = placed[i].rect;
      widgets.add(
        SignatureOverlay(
          pageSize: pageSize,
          rect: uiRect,
          sig: sig,
          pageNumber: pageNumber,
          placedIndex: i,
          onSelectPlaced: onSelectPlaced,
        ),
      );
    }

    final currentRect = ref.watch(currentRectProvider);
    final editingEnabled = ref.watch(editingEnabledProvider);
    final showActive =
        currentRect != null &&
        editingEnabled &&
        (pdf.signedPage == null || pdf.signedPage == pageNumber) &&
        pdf.currentPage == pageNumber;

    if (showActive) {
      widgets.add(
        SignatureOverlay(
          pageSize: pageSize,
          rect: currentRect,
          sig: sig,
          pageNumber: pageNumber,
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
