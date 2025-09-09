import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/data/model/model.dart' as model;

import '../../../../data/services/export_providers.dart';
import '../../signature/view_model/signature_controller.dart';
import '../../signature/view_model/signature_library.dart';
import 'image_editor_dialog.dart';
import '../../signature/widgets/signature_card.dart';

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
    final sig = ref.watch(signatureProvider);
    final processed = ref.watch(processedSignatureImageProvider);
    final bytes = processed ?? sig.imageBytes;
    final library = ref.watch(signatureLibraryProvider);
    final isExporting = ref.watch(exportingProvider);
    final disabled = widget.disabled || isExporting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (library.isNotEmpty) ...[
          for (final a in library) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SignatureCard(
                  key: ValueKey('sig_card_${a.id}'),
                  asset:
                      (sig.asset?.id == a.id)
                          ? model.SignatureAsset(
                            id: a.id,
                            bytes: (processed ?? a.bytes),
                            name: a.name,
                          )
                          : a,
                  rotationDeg: (sig.asset?.id == a.id) ? sig.rotation : 0.0,
                  disabled: disabled,
                  onDelete:
                      () => ref
                          .read(signatureLibraryProvider.notifier)
                          .remove(a.id),
                  onAdjust: () async {
                    ref
                        .read(signatureProvider.notifier)
                        .setImageFromLibrary(asset: a);
                    if (!mounted) return;
                    await showDialog(
                      context: context,
                      builder: (_) => const ImageEditorDialog(),
                    );
                  },
                  onTap: () {
                    // Never reassign placed signatures via tap; only set active overlay source
                    ref
                        .read(signatureProvider.notifier)
                        .setImageFromLibrary(asset: a);
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
              child:
                  bytes == null
                      ? Text(l.noSignatureLoaded)
                      : SignatureCard(
                        asset: model.SignatureAsset(
                          id: '',
                          bytes: bytes,
                          name: '',
                        ),
                        rotationDeg: sig.rotation,
                        disabled: disabled,
                        useCurrentBytesForDrag: true,
                        onDelete: () {
                          ref
                              .read(signatureProvider.notifier)
                              .clearActiveOverlay();
                          ref.read(signatureProvider.notifier).clearImage();
                        },
                        onAdjust: () async {
                          if (!mounted) return;
                          await showDialog(
                            context: context,
                            builder: (_) => const ImageEditorDialog(),
                          );
                        },
                      ),
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
                                final b =
                                    loaded ??
                                    ref.read(processedSignatureImageProvider) ??
                                    ref.read(signatureProvider).imageBytes;
                                if (b != null) {
                                  final id = ref
                                      .read(signatureLibraryProvider.notifier)
                                      .add(b, name: 'image');
                                  final asset = ref
                                      .read(signatureLibraryProvider.notifier)
                                      .byId(id);
                                  if (asset != null) {
                                    ref
                                        .read(signatureProvider.notifier)
                                        .setImageFromLibrary(asset: asset);
                                  }
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
                                final b =
                                    drawn ??
                                    ref.read(processedSignatureImageProvider) ??
                                    ref.read(signatureProvider).imageBytes;
                                if (b != null) {
                                  final id = ref
                                      .read(signatureLibraryProvider.notifier)
                                      .add(b, name: 'drawing');
                                  final asset = ref
                                      .read(signatureLibraryProvider.notifier)
                                      .byId(id);
                                  if (asset != null) {
                                    ref
                                        .read(signatureProvider.notifier)
                                        .setImageFromLibrary(asset: asset);
                                  }
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
