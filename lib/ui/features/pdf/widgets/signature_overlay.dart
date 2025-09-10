import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../domain/models/model.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'image_editor_dialog.dart';
import '../../signature/widgets/rotated_signature_image.dart';

/// Renders a single signature overlay (either interactive or placed) on a page.
class SignatureOverlay extends ConsumerWidget {
  const SignatureOverlay({
    super.key,
    required this.pageSize,
    required this.rect,
    required this.sig,
    required this.pageNumber,
    this.placedIndex,
    this.onDragSignature,
    this.onResizeSignature,
    this.onConfirmSignature,
    this.onClearActiveOverlay,
    this.onSelectPlaced,
  });

  final Size pageSize;
  final Rect rect;
  final SignatureCard sig;
  final int pageNumber;
  final int? placedIndex;

  // Callbacks used by interactive overlay
  final ValueChanged<Offset>? onDragSignature;
  final ValueChanged<Offset>? onResizeSignature;
  final VoidCallback? onConfirmSignature;
  final VoidCallback? onClearActiveOverlay;
  // Callback for selecting a placed overlay
  final ValueChanged<int?>? onSelectPlaced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / pageSize.width;
        final scaleY = constraints.maxHeight / pageSize.height;
        final left = rect.left * scaleX;
        final top = rect.top * scaleY;
        final width = rect.width * scaleX;
        final height = rect.height * scaleY;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: _buildContent(context, ref, scaleX, scaleY),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    double scaleX,
    double scaleY,
  ) {
    final selectedIdx =
        ref.read(documentRepositoryProvider).selectedPlacementIndex;
    final bool isPlaced = placedIndex != null;
    final bool isSelected = isPlaced && selectedIdx == placedIndex;
    final Color borderColor = isPlaced ? Colors.red : Colors.indigo;
    final double borderWidth = isPlaced ? (isSelected ? 3.0 : 2.0) : 2.0;

    // Instead of DecoratedBox, use a Stack to control layering
    Widget content = Stack(
      alignment: Alignment.center,
      children: [
        // Background layer (semi-transparent color)
        Positioned.fill(
          child: Container(
            color: Color.fromRGBO(
              0,
              0,
              0,
              0.05 + math.min(0.25, (sig.graphicAdjust.contrast - 1.0).abs()),
            ),
          ),
        ),
        // Signature image layer
        _SignatureImage(
          interactive: interactive,
          placedIndex: placedIndex,
          pageNumber: pageNumber,
          sig: sig,
        ),
        // Border layer (on top, using Positioned.fill with a transparent background)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: borderWidth),
            ),
          ),
        ),
        // Resize handle (only for interactive mode, on top of everything)
        if (interactive)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              key: const Key('signature_handle'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate:
                  (d) => onResizeSignature?.call(
                    Offset(d.delta.dx / scaleX, d.delta.dy / scaleY),
                  ),
              child: const Icon(Icons.open_in_full, size: 20),
            ),
          ),
      ],
    );

    if (interactive) {
      content = GestureDetector(
        key: const Key('signature_overlay'),
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {},
        onPanUpdate:
            (d) => onDragSignature?.call(
              Offset(d.delta.dx / scaleX, d.delta.dy / scaleY),
            ),
        onSecondaryTapDown:
            (d) => _showActiveMenu(context, d.globalPosition, ref, null),
        onLongPressStart:
            (d) => _showActiveMenu(context, d.globalPosition, ref, null),
        child: content,
      );
    } else {
      content = GestureDetector(
        key: Key('placed_signature_${placedIndex ?? 'x'}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelectPlaced?.call(placedIndex),
        onSecondaryTapDown: (d) {
          if (placedIndex != null) {
            _showActiveMenu(context, d.globalPosition, ref, placedIndex);
          }
        },
        onLongPressStart: (d) {
          if (placedIndex != null) {
            _showActiveMenu(context, d.globalPosition, ref, placedIndex);
          }
        },
        child: content,
      );
    }
    return content;
  }

  void _showActiveMenu(
    BuildContext context,
    Offset globalPos,
    WidgetRef ref,
    int? placedIndex,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      items: [
        // if not placed, show Adjust and Confirm option
        if (placedIndex == null) ...[
          PopupMenuItem<String>(
            key: const Key('ctx_active_confirm'),
            value: 'confirm',
            child: Text(AppLocalizations.of(context).confirm),
          ),
          PopupMenuItem<String>(
            key: const Key('ctx_active_adjust'),
            value: 'adjust',
            child: Text(AppLocalizations.of(context).adjustGraphic),
          ),
        ],
        PopupMenuItem<String>(
          key: const Key('ctx_active_delete'),
          value: 'delete',
          child: Text(AppLocalizations.of(context).delete),
        ),
      ],
    ).then((choice) {
      if (choice == 'confirm') {
        if (placedIndex == null) {
          onConfirmSignature?.call();
        }
        // For placed, confirm does nothing
      } else if (choice == 'delete') {
        if (placedIndex == null) {
          onClearActiveOverlay?.call();
        } else {
          ref
              .read(documentRepositoryProvider.notifier)
              .removePlacement(page: pageNumber, index: placedIndex);
        }
      } else if (choice == 'adjust') {
        showDialog(context: context, builder: (_) => const ImageEditorDialog());
      }
    });
  }
}

class _SignatureImage extends ConsumerWidget {
  const _SignatureImage({
    required this.interactive,
    required this.placedIndex,
    required this.pageNumber,
    required this.sig,
  });

  final bool interactive;
  final int? placedIndex;
  final int pageNumber;
  final SignatureCard sig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Uint8List? bytes;
    if (interactive) {
      final processed = ref.watch(processedSignatureImageProvider);
      bytes = processed ?? sig.asset.bytes;
    } else if (placedIndex != null) {
      final placementList =
          ref.read(documentRepositoryProvider).placementsByPage[pageNumber];
      final placement =
          (placementList != null && placedIndex! < placementList.length)
              ? placementList[placedIndex!]
              : null;
      final imgId = (placement?.asset)?.id;
      if (imgId != null && imgId.isNotEmpty) {
        final lib = ref.watch(signatureAssetRepositoryProvider);
        for (final a in lib) {
          if (a.id == imgId) {
            bytes = a.bytes;
            break;
          }
        }
      }
      bytes ??= ref.read(processedSignatureImageProvider) ?? sig.asset.bytes;
    }

    if (bytes == null) {
      String label;
      try {
        label = AppLocalizations.of(context).signature;
      } catch (_) {
        label = 'Signature';
      }
      return Center(child: Text(label));
    }

    // Use live rotation for interactive overlay; stored rotation for placed
    double rotationDeg = 0.0;
    if (interactive) {
      rotationDeg = sig.rotationDeg;
    } else if (placedIndex != null) {
      final placementList =
          ref.read(documentRepositoryProvider).placementsByPage[pageNumber];
      if (placementList != null && placedIndex! < placementList.length) {
        rotationDeg = placementList[placedIndex!].rotationDeg;
      }
    }
    return RotatedSignatureImage(bytes: bytes, rotationDeg: rotationDeg);
  }
}
