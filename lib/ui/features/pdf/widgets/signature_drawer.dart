import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../data/services/providers.dart';
import '../view_model/view_model.dart';
import 'image_editor_dialog.dart';

/// Data passed when dragging a signature card.
class SignatureDragData {
  const SignatureDragData();
}

class SignatureDrawer extends ConsumerStatefulWidget {
  const SignatureDrawer({
    super.key,
    required this.disabled,
    required this.onLoadSignatureFromFile,
    required this.onOpenDrawCanvas,
  });

  final bool disabled;
  final VoidCallback onLoadSignatureFromFile;
  final VoidCallback onOpenDrawCanvas;

  @override
  ConsumerState<SignatureDrawer> createState() => _SignatureDrawerState();
}

class _SignatureDrawerState extends ConsumerState<SignatureDrawer> {
  Future<void> _openSignatureMenuAt(Offset globalPosition) async {
    final l = AppLocalizations.of(context);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        PopupMenuItem(
          key: const Key('mi_signature_delete'),
          value: 'delete',
          child: Text(l.delete),
        ),
        PopupMenuItem(
          key: const Key('mi_signature_adjust'),
          value: 'adjust',
          child: const Text('Adjust graphic'),
        ),
      ],
    );

    switch (selected) {
      case 'delete':
        ref.read(signatureProvider.notifier).clearActiveOverlay();
        ref.read(signatureProvider.notifier).clearImage();
        break;
      case 'adjust':
        if (!mounted) return;
        // Open ImageEditorDialog
        await showDialog(
          context: context,
          builder: (_) => const ImageEditorDialog(),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sig = ref.watch(signatureProvider);
    final processed = ref.watch(processedSignatureImageProvider);
    final bytes = processed ?? sig.imageBytes;
    final isExporting = ref.watch(exportingProvider);
    final disabled = widget.disabled || isExporting;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              l.signature,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          // Existing signature card (draggable when bytes available)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                key: const Key('gd_signature_card_area'),
                behavior: HitTestBehavior.opaque,
                onSecondaryTapDown: (details) {
                  if (bytes != null && !disabled) {
                    _openSignatureMenuAt(details.globalPosition);
                  }
                },
                onLongPressStart: (details) {
                  if (bytes != null && !disabled) {
                    _openSignatureMenuAt(details.globalPosition);
                  }
                },
                child: SizedBox(
                  height: 120,
                  child:
                      bytes == null
                          ? Center(
                            child: Text(
                              l.noPdfLoaded,
                              textAlign: TextAlign.center,
                            ),
                          )
                          : _DraggableSignaturePreview(
                            bytes: bytes,
                            disabled: disabled,
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // New signature card
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.createNewSignature,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('btn_drawer_load_signature'),
                      onPressed:
                          disabled ? null : widget.onLoadSignatureFromFile,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(l.loadSignatureFromFile),
                    ),
                    OutlinedButton.icon(
                      key: const Key('btn_drawer_draw_signature'),
                      onPressed: disabled ? null : widget.onOpenDrawCanvas,
                      icon: const Icon(Icons.gesture),
                      label: Text(l.drawSignature),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Adjustments are accessed via "Adjust graphic" in the popup menu
        ],
      ),
    );
  }
}

class _DraggableSignaturePreview extends StatelessWidget {
  const _DraggableSignaturePreview({
    required this.bytes,
    required this.disabled,
  });
  final Uint8List bytes;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.memory(bytes, fit: BoxFit.contain),
    );
    if (disabled) return child;
    return Draggable<SignatureDragData>(
      data: const SignatureDragData(),
      feedback: Opacity(
        opacity: 0.8,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 160, height: 80),
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
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: child),
      child: child,
    );
  }
}
