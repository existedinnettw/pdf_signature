import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../view_model/view_model.dart';
import 'adjustments_panel.dart';

class ImageEditorDialog extends ConsumerWidget {
  const ImageEditorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    final l = AppLocalizations.of(context);
    final sig = ref.watch(signatureProvider);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.signature,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                // Preview
                SizedBox(
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final processed = ref.watch(
                            processedSignatureImageProvider,
                          );
                          final bytes = processed ?? sig.imageBytes;
                          if (bytes == null) {
                            return Text(l.noSignatureLoaded);
                          }
                          return Image.memory(bytes, fit: BoxFit.contain);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Adjustments
                AdjustmentsPanel(sig: sig),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(l10n.rotate),
                    Expanded(
                      child: Slider(
                        key: const Key('sld_rotation'),
                        min: -180,
                        max: 180,
                        divisions: 72,
                        value: sig.rotation,
                        onChanged:
                            (v) => ref
                                .read(signatureProvider.notifier)
                                .setRotation(v),
                      ),
                    ),
                    Text('${sig.rotation.toStringAsFixed(0)}°'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const Key('btn_image_editor_close'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
