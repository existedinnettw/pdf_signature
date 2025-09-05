import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../data/model/model.dart';
import '../view_model/view_model.dart';
import 'image_editor_dialog.dart';
import '../../../common/menu_labels.dart';
import 'rotated_signature_image.dart';

/// Renders a single signature overlay (either interactive or placed) on a page.
class SignatureOverlay extends ConsumerWidget {
  const SignatureOverlay({
    super.key,
    required this.pageSize,
    required this.rect,
    required this.sig,
    required this.pageNumber,
    this.interactive = true,
    this.placedIndex,
    this.onDragSignature,
    this.onResizeSignature,
    this.onConfirmSignature,
    this.onClearActiveOverlay,
    this.onSelectPlaced,
  });

  final Size pageSize;
  final Rect rect;
  final SignatureState sig;
  final int pageNumber;
  final bool interactive;
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
    final selectedIdx = ref.read(pdfProvider).selectedPlacementIndex;
    final bool isPlaced = placedIndex != null;
    final bool isSelected = isPlaced && selectedIdx == placedIndex;
    final Color borderColor = isPlaced ? Colors.red : Colors.indigo;
    final double borderWidth = isPlaced ? (isSelected ? 3.0 : 2.0) : 2.0;

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          0,
          0,
          0,
          0.05 + math.min(0.25, (sig.contrast - 1.0).abs()),
        ),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _SignatureImage(
            interactive: interactive,
            placedIndex: placedIndex,
            pageNumber: pageNumber,
            sig: sig,
          ),
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
      ),
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
        onSecondaryTapDown: (d) => _showActiveMenu(context, d.globalPosition),
        onLongPressStart: (d) => _showActiveMenu(context, d.globalPosition),
        child: content,
      );
    } else {
      content = GestureDetector(
        key: Key('placed_signature_${placedIndex ?? 'x'}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelectPlaced?.call(placedIndex),
        onSecondaryTapDown: (d) {
          if (placedIndex != null) {
            _showPlacedMenu(context, ref, d.globalPosition);
          }
        },
        onLongPressStart: (d) {
          if (placedIndex != null) {
            _showPlacedMenu(context, ref, d.globalPosition);
          }
        },
        child: content,
      );
    }
    return content;
  }

  void _showActiveMenu(BuildContext context, Offset globalPos) {
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
          key: const Key('ctx_active_confirm'),
          value: 'confirm',
          child: Text(MenuLabels.confirm(context)),
        ),
        PopupMenuItem<String>(
          key: const Key('ctx_active_delete'),
          value: 'delete',
          child: Text(MenuLabels.delete(context)),
        ),
        PopupMenuItem<String>(
          key: const Key('ctx_active_adjust'),
          value: 'adjust',
          child: Text(MenuLabels.adjustGraphic(context)),
        ),
      ],
    ).then((choice) {
      if (choice == 'confirm') {
        onConfirmSignature?.call();
      } else if (choice == 'delete') {
        onClearActiveOverlay?.call();
      } else if (choice == 'adjust') {
        showDialog(context: context, builder: (_) => const ImageEditorDialog());
      }
    });
  }

  void _showPlacedMenu(BuildContext context, WidgetRef ref, Offset globalPos) {
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
          child: Text(MenuLabels.delete(context)),
        ),
        PopupMenuItem<String>(
          key: const Key('ctx_placed_adjust'),
          value: 'adjust',
          child: Text(MenuLabels.adjustGraphic(context)),
        ),
      ],
    ).then((choice) {
      switch (choice) {
        case 'delete':
          if (placedIndex != null) {
            ref
                .read(pdfProvider.notifier)
                .removePlacement(page: pageNumber, index: placedIndex!);
          }
          break;
        case 'adjust':
          showDialog(
            context: context,
            builder: (ctx) => const ImageEditorDialog(),
          );
          break;
        default:
          break;
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
  final SignatureState sig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Uint8List? bytes;
    if (interactive) {
      final processed = ref.watch(processedSignatureImageProvider);
      bytes = processed ?? sig.imageBytes;
    } else if (placedIndex != null) {
      // Use the image assigned to this placement
      final imgId = ref
          .read(pdfProvider)
          .placementImageByPage[pageNumber]
          ?.elementAt(placedIndex!);
      if (imgId != null) {
        final lib = ref.watch(signatureLibraryProvider);
        for (final a in lib) {
          if (a.id == imgId) {
            bytes = a.bytes;
            break;
          }
        }
      }
      // Fallback to current processed
      bytes ??= ref.read(processedSignatureImageProvider) ?? sig.imageBytes;
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

    return RotatedSignatureImage(
      bytes: bytes,
      rotationDeg: interactive ? sig.rotation : 0.0,
      enableAngleAwareScale: interactive,
      fit: BoxFit.contain,
      wrapInRepaintBoundary: true,
    );
  }
}
