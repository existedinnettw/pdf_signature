import 'package:flutter/material.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'adjustments_panel.dart';
// No live preview wiring in simplified dialog

class ImageEditorDialog extends StatefulWidget {
  const ImageEditorDialog({super.key});

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  // Local-only state for demo/tests; no persistence to repositories.
  bool _aspectLocked = false;
  bool _bgRemoval = false;
  double _contrast = 1.0; // 0..2
  double _brightness = 0.0; // -1..1
  double _rotation = 0.0; // -180..180

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final l = AppLocalizations.of(context);
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
                // Preview placeholder; no actual processed bytes wired
                SizedBox(
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No signature loaded')),
                  ),
                ),
                const SizedBox(height: 12),
                // Adjustments
                AdjustmentsPanel(
                  aspectLocked: _aspectLocked,
                  bgRemoval: _bgRemoval,
                  contrast: _contrast,
                  brightness: _brightness,
                  onAspectLockedChanged:
                      (v) => setState(() => _aspectLocked = v),
                  onBgRemovalChanged: (v) => setState(() => _bgRemoval = v),
                  onContrastChanged: (v) => setState(() => _contrast = v),
                  onBrightnessChanged: (v) => setState(() => _brightness = v),
                ),
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
                        value: _rotation,
                        onChanged: (v) => setState(() => _rotation = v),
                      ),
                    ),
                    Text('${_rotation.toStringAsFixed(0)}°'),
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
