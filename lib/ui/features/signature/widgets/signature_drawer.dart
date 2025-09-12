import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
// No direct model construction needed here

import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import '../../pdf/widgets/image_editor_dialog.dart';
import 'signature_card.dart';

/// Data for drag-and-drop is in signature_drag_data.dart

class SignatureDrawer extends ConsumerStatefulWidget {
  const SignatureDrawer({
    super.key,
    required this.disabled,
    required this.onLoadSignatureFromFile,
    required this.onOpenDrawCanvas,
  });

  final bool disabled;
  // Return the loaded bytes (if any) so we can add the exact image to the library immediately.
  final Future<Uint8List?> Function() onLoadSignatureFromFile;
  // Return the drawn bytes (if any) so we can add it to the library immediately.
  final Future<Uint8List?> Function() onOpenDrawCanvas;

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
                child: SignatureCard(
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
                    await showDialog(
                      context: context,
                      builder: (_) => const ImageEditorDialog(),
                    );
                  },
                  onTap: () {
                    // state = const Rect.fromLTWH(0.2, 0.2, 0.3, 0.15);
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
                                final loaded =
                                    await widget.onLoadSignatureFromFile();
                                final b = loaded;
                                if (b != null) {
                                  ref
                                      .read(
                                        signatureAssetRepositoryProvider
                                            .notifier,
                                      )
                                      .add(b, name: 'image');
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
                                final drawn = await widget.onOpenDrawCanvas();
                                final b = drawn;
                                if (b != null) {
                                  ref
                                      .read(
                                        signatureAssetRepositoryProvider
                                            .notifier,
                                      )
                                      .add(b, name: 'drawing');
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
