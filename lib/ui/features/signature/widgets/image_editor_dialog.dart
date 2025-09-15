import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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
  late Uint8List _processedBytes;

  @override
  void initState() {
    super.initState();
    _aspectLocked = false; // Not persisted in GraphicAdjust
    _bgRemoval = widget.initialGraphicAdjust.bgRemoval;
    _contrast = widget.initialGraphicAdjust.contrast;
    _brightness = 1.0; // Changed from 0.0 to 1.0
    _rotation = widget.initialRotation;
    _processedBytes = widget.asset.bytes; // Initialize with original bytes
  }

  /// Update processed image bytes when processing parameters change
  void _updateProcessedBytes() {
    try {
      final decoded = img.decodeImage(widget.asset.bytes);
      if (decoded != null) {
        img.Image processed = decoded;

        // Apply contrast and brightness first
        if (_contrast != 1.0 || _brightness != 1.0) {
          processed = img.adjustColor(
            processed,
            contrast: _contrast,
            brightness: _brightness,
          );
        }

        // Apply background removal after color adjustments
        if (_bgRemoval) {
          processed = _removeBackground(processed);
        }

        // Encode back to PNG to preserve transparency
        _processedBytes = Uint8List.fromList(img.encodePng(processed));
      }
    } catch (e) {
      // If processing fails, keep original bytes
      _processedBytes = widget.asset.bytes;
    }
  }

  /// Remove near-white background using simple threshold approach for maximum speed
  /// TODO: remove double loops with SIMD matrix 
  img.Image _removeBackground(img.Image image) {
    final result =
        image.hasAlpha ? img.Image.from(image) : image.convert(numChannels: 4);

    // Simple and fast: single pass through all pixels
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Simple threshold: if pixel is close to white, make it transparent
        const int threshold = 240; // Very close to white
        if (r >= threshold && g >= threshold && b >= threshold) {
          result.setPixelRgba(x, y, r, g, b, 0);
        }
      }
    }

    return result;
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
                        bytes: _processedBytes,
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
                  onBgRemovalChanged:
                      (v) => setState(() {
                        _bgRemoval = v;
                        _updateProcessedBytes();
                      }),
                  onContrastChanged:
                      (v) => setState(() {
                        _contrast = v;
                        _updateProcessedBytes();
                      }),
                  onBrightnessChanged:
                      (v) => setState(() {
                        _brightness = v;
                        _updateProcessedBytes();
                      }),
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
