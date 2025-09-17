import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/addons.dart';
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
  // UI state
  late bool _aspectLocked;
  late bool _bgRemoval;
  late double _contrast;
  late double _brightness;
  late double _rotation;

  // Cached image data
  late Uint8List _originalBytes; // Original asset bytes (never mutated)
  Uint8List?
  _processedBgRemovedBytes; // Cached brightness/contrast adjusted then bg-removed bytes
  img.Image? _decodedBase; // Decoded original for processing

  // Debounce for background removal (in case we later tie it to brightness/contrast)
  Timer? _bgRemovalDebounce;

  @override
  void initState() {
    super.initState();
    _aspectLocked = false; // Not persisted in GraphicAdjust
    _bgRemoval = widget.initialGraphicAdjust.bgRemoval;
    _contrast = widget.initialGraphicAdjust.contrast;
    _brightness = widget.initialGraphicAdjust.brightness;
    _rotation = widget.initialRotation;
    _originalBytes = widget.asset.bytes;
    // Decode lazily only if/when background removal is needed
    if (_bgRemoval) {
      _scheduleBgRemovalReprocess(immediate: true);
    }
  }

  Uint8List get _displayBytes =>
      _bgRemoval
          ? (_processedBgRemovedBytes ?? _originalBytes)
          : _originalBytes;

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
    _decodedBase ??= img.decodeImage(_originalBytes);
    final base = _decodedBase;
    if (base == null) return;
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
    const int threshold = 240;
    if (!working.hasAlpha) {
      working = working.convert(numChannels: 4);
    }
    for (int y = 0; y < working.height; y++) {
      for (int x = 0; x < working.width; x++) {
        final p = working.getPixel(x, y);
        final r = p.r, g = p.g, b = p.b;
        if (r >= threshold && g >= threshold && b >= threshold) {
          working.setPixelRgba(x, y, r, g, b, 0);
        }
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(working));
    if (!mounted) return;
    setState(() => _processedBgRemovedBytes = bytes);
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
                      child:
                          _bgRemoval
                              ? RotatedSignatureImage(
                                bytes: _displayBytes,
                                rotationDeg: _rotation,
                              )
                              : ColorFiltered(
                                colorFilter: _currentColorFilter(),
                                child: RotatedSignatureImage(
                                  bytes: _displayBytes,
                                  rotationDeg: _rotation,
                                ),
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
