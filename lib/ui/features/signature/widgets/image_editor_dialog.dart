import 'package:flutter/material.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../../pdf/widgets/adjustments_panel.dart';
import '../../../../domain/models/model.dart' as domain;
import 'rotated_signature_image.dart';

class ImageEditorResult {
  final double rotation;
  final domain.GraphicAdjust graphicAdjust;

  const ImageEditorResult({
    required this.rotation,
    required this.graphicAdjust,
  });
}

class ImageEditorDialog extends StatefulWidget {
  const ImageEditorDialog({
    super.key,
    required this.asset,
    required this.initialRotation,
    required this.initialGraphicAdjust,
  });

  final domain.SignatureAsset asset;
  final double initialRotation;
  final domain.GraphicAdjust initialGraphicAdjust;

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  late bool _aspectLocked;
  late bool _bgRemoval;
  late double _contrast;
  late double _brightness;
  late double _rotation;

  @override
  void initState() {
    super.initState();
    _aspectLocked = false; // Not persisted in GraphicAdjust
    _bgRemoval = widget.initialGraphicAdjust.bgRemoval;
    _contrast = widget.initialGraphicAdjust.contrast;
    _brightness = widget.initialGraphicAdjust.brightness;
    _rotation = widget.initialRotation;
  }

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
                // Preview with actual signature image
                SizedBox(
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: RotatedSignatureImage(
                        bytes: widget.asset.bytes,
                        rotationDeg: _rotation,
                      ),
                    ),
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
                      onPressed:
                          () => Navigator.of(context).pop(
                            ImageEditorResult(
                              rotation: _rotation,
                              graphicAdjust: domain.GraphicAdjust(
                                contrast: _contrast,
                                brightness: _brightness,
                                bgRemoval: _bgRemoval,
                              ),
                            ),
                          ),
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
