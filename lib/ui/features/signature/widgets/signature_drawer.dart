// no bytes here; image-first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
// Direct model construction is needed for creating SignatureAssets

import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/signature_asset.dart';
import 'package:image/image.dart' as img;
import 'image_editor_dialog.dart';
import 'signature_card_view.dart';
// Removed PdfViewModel import; no direct interaction from drawer on tap

/// Data for drag-and-drop is in signature_drag_data.dart

class SignatureDrawer extends ConsumerStatefulWidget {
  const SignatureDrawer({
    super.key,
    required this.disabled,
    required this.onLoadSignatureFromFile,
    required this.onOpenDrawCanvas,
  });

  final bool disabled;
  // Return decoded image so inner layers don't decode.
  final Future<img.Image?> Function() onLoadSignatureFromFile;
  // Return decoded image so inner layers don't decode.
  final Future<img.Image?> Function() onOpenDrawCanvas;

  @override
  ConsumerState<SignatureDrawer> createState() => _SignatureDrawerState();
}

class _SignatureDrawerState extends ConsumerState<SignatureDrawer> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final library = ref.watch(signatureCardRepositoryProvider);
    // Exporting flag lives in ui_services; keep drawer interactive regardless here.
    final isExporting = false;
    final disabled = widget.disabled || isExporting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (library.isNotEmpty) ...[
          for (final card in library) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SignatureCardView(
                  key: ValueKey('sig_card_${library.indexOf(card)}'),
                  asset: card.asset,
                  rotationDeg: card.rotationDeg,
                  graphicAdjust: card.graphicAdjust,
                  disabled: disabled,
                  onDelete:
                      () => ref
                          .read(signatureCardRepositoryProvider.notifier)
                          .remove(card),
                  onAdjust: () async {
                    if (!mounted) return;
                    final result = await showDialog<ImageEditorResult>(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) => ImageEditorDialog(
                            asset: card.asset,
                            initialRotation: card.rotationDeg,
                            initialGraphicAdjust: card.graphicAdjust,
                          ),
                    );
                    if (result != null && mounted) {
                      ref
                          .read(signatureCardRepositoryProvider.notifier)
                          .update(card, result.rotation, result.graphicAdjust);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (library.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.noSignatureLoaded),
            ),
          ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
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
                          disabled
                              ? null
                              : () async {
                                final image =
                                    await widget.onLoadSignatureFromFile();
                                if (image != null) {
                                  final asset = SignatureAsset(
                                    sigImage: image,
                                    name: 'image',
                                  );
                                  ref
                                      .read(
                                        signatureAssetRepositoryProvider
                                            .notifier,
                                      )
                                      .addImage(image, name: 'image');
                                  ref
                                      .read(
                                        signatureCardRepositoryProvider
                                            .notifier,
                                      )
                                      .addWithAsset(asset, 0.0);
                                }
                              },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(l.loadSignatureFromFile),
                    ),
                    OutlinedButton.icon(
                      key: const Key('btn_drawer_draw_signature'),
                      onPressed:
                          disabled
                              ? null
                              : () async {
                                final image = await widget.onOpenDrawCanvas();
                                if (image != null) {
                                  final asset = SignatureAsset(
                                    sigImage: image,
                                    name: 'drawing',
                                  );
                                  ref
                                      .read(
                                        signatureAssetRepositoryProvider
                                            .notifier,
                                      )
                                      .addImage(image, name: 'drawing');
                                  ref
                                      .read(
                                        signatureCardRepositoryProvider
                                            .notifier,
                                      )
                                      .addWithAsset(asset, 0.0);
                                }
                              },
                      icon: const Icon(Icons.gesture),
                      label: Text(l.drawSignature),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
