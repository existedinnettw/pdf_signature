import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/domain/models/model.dart' as domain;
import 'signature_drag_data.dart';
import 'rotated_signature_image.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../view_model/signature_view_model.dart';
import '../view_model/dragging_signature_view_model.dart';

class SignatureCard extends ConsumerWidget {
  const SignatureCard({
    super.key,
    required this.asset,
    required this.disabled,
    required this.onDelete,
    this.onTap,
    this.onAdjust,
    this.useCurrentBytesForDrag = false,
    this.rotationDeg = 0.0,
    this.graphicAdjust = const domain.GraphicAdjust(),
  });
  final domain.SignatureAsset asset;
  final bool disabled;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAdjust;
  final bool useCurrentBytesForDrag;
  final double rotationDeg;
  final domain.GraphicAdjust graphicAdjust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayData = ref
        .watch(signatureViewModelProvider)
        .getDisplaySignatureData(asset, graphicAdjust);
    // Fit inside 96x64 with 6px padding using the shared rotated image widget
    const boxW = 96.0, boxH = 64.0, pad = 6.0;
    Widget coreImage = RotatedSignatureImage(
      bytes: displayData.bytes,
      rotationDeg: rotationDeg,
    );
    Widget img =
        (displayData.colorMatrix != null)
            ? ColorFiltered(
              colorFilter: ColorFilter.matrix(displayData.colorMatrix!),
              child: coreImage,
            )
            : coreImage;
    Widget base = SizedBox(
      width: 96,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(pad),
                  child: SizedBox(
                    width: boxW - pad * 2,
                    height: boxH - pad * 2,
                    child: img,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: disabled ? null : onDelete,
                tooltip: 'Remove',
                padding: const EdgeInsets.all(2),
              ),
            ),
          ],
        ),
      ),
    );
    Widget child = onTap != null ? InkWell(onTap: onTap, child: base) : base;
    // Add context menu for adjust/delete on right-click or long-press
    child = GestureDetector(
      key: const Key('gd_signature_card_area'),
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown:
          disabled
              ? null
              : (details) async {
                final selected = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                  ),
                  items: [
                    PopupMenuItem(
                      key: const Key('mi_signature_adjust'),
                      value: 'adjust',
                      child: Text(AppLocalizations.of(context).adjustGraphic),
                    ),
                    PopupMenuItem(
                      key: const Key('mi_signature_delete'),
                      value: 'delete',
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ],
                );
                if (selected == 'adjust') {
                  onAdjust?.call();
                } else if (selected == 'delete') {
                  onDelete();
                }
              },
      onLongPressStart:
          disabled
              ? null
              : (details) async {
                final selected = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                  ),
                  items: [
                    PopupMenuItem(
                      key: const Key('mi_signature_adjust'),
                      value: 'adjust',
                      child: Text(AppLocalizations.of(context).adjustGraphic),
                    ),
                    PopupMenuItem(
                      key: const Key('mi_signature_delete'),
                      value: 'delete',
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ],
                );
                if (selected == 'adjust') {
                  onAdjust?.call();
                } else if (selected == 'delete') {
                  onDelete();
                }
              },
      child: child,
    );
    if (disabled) return child;
    return Draggable<SignatureDragData>(
      data:
          useCurrentBytesForDrag
              ? const SignatureDragData()
              : SignatureDragData(
                card: domain.SignatureCard(
                  asset: asset,
                  rotationDeg: rotationDeg,
                  graphicAdjust: graphicAdjust,
                ),
              ),
      onDragStarted: () {
        ref.read(isDraggingSignatureViewModelProvider.notifier).state = true;
      },
      onDragEnd: (_) {
        ref.read(isDraggingSignatureViewModelProvider.notifier).state = false;
      },
      feedback: Opacity(
        opacity: 0.9,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 160, height: 100),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(blurRadius: 8, color: Colors.black26),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child:
                  (displayData.colorMatrix != null)
                      ? ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          displayData.colorMatrix!,
                        ),
                        child: RotatedSignatureImage(
                          bytes: displayData.bytes,
                          rotationDeg: rotationDeg,
                        ),
                      )
                      : RotatedSignatureImage(
                        bytes: displayData.bytes,
                        rotationDeg: rotationDeg,
                      ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: child),
      child: child,
    );
  }
}
