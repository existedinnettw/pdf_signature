import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/addons.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../../pdf/widgets/adjustments_panel.dart';
import '../../../../domain/models/model.dart' as domain;
import 'rotated_signature_image.dart';
import '../../../../utils/background_removal.dart' as br;

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
  // UI state
  late bool _aspectLocked;
  late bool _bgRemoval;
  late double _contrast;
  late double _brightness;
  late final ValueNotifier<double> _rotation;

  // Cached image data
  late img.Image _originalImage; // Original asset image
  img.Image?
  _processedBgRemovedImage; // Cached brightness/contrast adjusted then bg-removed image

  // Debounce for background removal (in case we later tie it to brightness/contrast)
  Timer? _bgRemovalDebounce;

  @override
  void initState() {
    super.initState();
    _aspectLocked = false; // Not persisted in GraphicAdjust
    _bgRemoval = widget.initialGraphicAdjust.bgRemoval;
    _contrast = widget.initialGraphicAdjust.contrast;
    _brightness = widget.initialGraphicAdjust.brightness;
    _rotation = ValueNotifier<double>(widget.initialRotation);
    _originalImage = widget.asset.sigImage;
    // If background removal initially enabled, precompute immediately
    if (_bgRemoval) {
      _scheduleBgRemovalReprocess(immediate: true);
    }
  }

  // No _displayBytes cache: the preview now uses img.Image directly.

  void _onBgRemovalChanged(bool value) {
    setState(() {
      _bgRemoval = value;
      if (value) {
        _scheduleBgRemovalReprocess(immediate: true);
      }
    });
  }

  void _scheduleBgRemovalReprocess({bool immediate = false}) {
    if (!_bgRemoval) return; // Only when enabled
    _bgRemovalDebounce?.cancel();
    if (immediate) {
      _recomputeBgRemoval();
    } else {
      _bgRemovalDebounce = Timer(
        const Duration(milliseconds: 120),
        _recomputeBgRemoval,
      );
    }
  }

  void _recomputeBgRemoval() {
    final base = _originalImage;
    // Apply brightness & contrast first (domain uses 1.0 neutral)
    img.Image working = img.Image.from(base);
    final needAdjust = _brightness != 1.0 || _contrast != 1.0;
    if (needAdjust) {
      working = img.adjustColor(
        working,
        brightness: _brightness,
        contrast: _contrast,
      );
    }
    // Then remove background on adjusted pixels
    working = br.removeNearWhiteBackground(working, threshold: 240);
    if (!mounted) return;
    setState(() {
      _processedBgRemovedImage = working;
    });
  }

  ColorFilter _currentColorFilter() {
    // The original domain model uses 1.0 as neutral for brightness/contrast.
    // colorfilter_generator expects values between -1..1 for adjustments when using addons.
    // We'll map: domain brightness (default 1.0) -> addon brightness(value-1)
    // Same for contrast.
    final bAddon = _brightness - 1.0; // so 1.0 => 0
    final cAddon = _contrast - 1.0; // so 1.0 => 0
    final generator = ColorFilterGenerator(
      name: 'dynamic_adjust',
      filters: [
        if (bAddon != 0) ColorFilterAddons.brightness(bAddon),
        if (cAddon != 0) ColorFilterAddons.contrast(cAddon),
      ],
    );
    // If neutral, return identity filter to avoid unnecessary matrix mul
    if (bAddon == 0 && cAddon == 0) {
      // Identity matrix
      return const ColorFilter.matrix(<double>[
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    return ColorFilter.matrix(generator.matrix);
  }

  @override
  void dispose() {
    _rotation.dispose();
    _bgRemovalDebounce?.cancel();
    super.dispose();
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
                // Preview: if bg removal active we already applied adjustments in CPU pipeline,
                // otherwise apply brightness/contrast via GPU ColorFilter.
                SizedBox(
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ValueListenableBuilder<double>(
                        valueListenable: _rotation,
                        builder: (context, rot, child) {
                          final image = RotatedSignatureImage(
                            image:
                                _bgRemoval
                                    ? (_processedBgRemovedImage ??
                                        _originalImage)
                                    : _originalImage,
                            rotationDeg: rot,
                          );
                          if (_bgRemoval) return image;
                          return ColorFiltered(
                            colorFilter: _currentColorFilter(),
                            child: image,
                          );
                        },
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
                  onBgRemovalChanged: (v) => _onBgRemovalChanged(v),
                  onContrastChanged:
                      (v) => setState(() {
                        _contrast = v;
                        if (_bgRemoval) _scheduleBgRemovalReprocess();
                      }),
                  onBrightnessChanged:
                      (v) => setState(() {
                        _brightness = v;
                        if (_bgRemoval) _scheduleBgRemovalReprocess();
                      }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(l10n.rotate),
                    Expanded(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _rotation,
                        builder: (context, rot, _) {
                          return Slider(
                            key: const Key('sld_rotation'),
                            min: -180,
                            max: 180,
                            divisions: 72,
                            value: rot,
                            onChanged: (v) => _rotation.value = v,
                          );
                        },
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: _rotation,
                      builder:
                          (context, rot, _) =>
                              Text('${rot.toStringAsFixed(0)}°'),
                    ),
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
                              rotation: _rotation.value,
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
