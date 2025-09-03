import 'package:flutter/material.dart';
import '../view_model/view_model.dart';
import 'signature_drag_data.dart';
import '../../../common/menu_labels.dart';

class SignatureCard extends StatelessWidget {
  const SignatureCard({
    super.key,
    required this.asset,
    required this.disabled,
    required this.onDelete,
    this.onTap,
    this.onAdjust,
    this.useCurrentBytesForDrag = false,
  });
  final SignatureAsset asset;
  final bool disabled;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAdjust;
  final bool useCurrentBytesForDrag;

  @override
  Widget build(BuildContext context) {
    final img = Image.memory(asset.bytes, fit: BoxFit.contain);
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
                child: Padding(padding: const EdgeInsets.all(6), child: img),
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
                      child: Text(MenuLabels.adjustGraphic(context)),
                    ),
                    PopupMenuItem(
                      key: const Key('mi_signature_delete'),
                      value: 'delete',
                      child: Text(MenuLabels.delete(context)),
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
                      child: Text(MenuLabels.adjustGraphic(context)),
                    ),
                    PopupMenuItem(
                      key: const Key('mi_signature_delete'),
                      value: 'delete',
                      child: Text(MenuLabels.delete(context)),
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
              : SignatureDragData(assetId: asset.id),
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
              child: Image.memory(asset.bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: child),
      child: child,
    );
  }
}
