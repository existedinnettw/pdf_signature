import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import '../../pdf/widgets/adjustments_panel.dart';
import '../../../../domain/models/model.dart' as domain;
import '../view_model/signature_view_model.dart';
import 'rotated_signature_image.dart';
import '../../../../data/services/signature_image_processing_service.dart';
import 'package:image/image.dart' as img;

class ImageEditorResult {
  final double rotation;
  final domain.GraphicAdjust graphicAdjust;

  const ImageEditorResult({
    required this.rotation,
    required this.graphicAdjust,
  });
}

class ImageEditorDialog extends ConsumerStatefulWidget {
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
  ConsumerState<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends ConsumerState<ImageEditorDialog> {
  late bool _aspectLocked;
  late bool _bgRemoval;
  late double _contrast;
  late double _brightness;
  late double _rotation;
  late Uint8List _processedBytes;
  img.Image? _decodedSource; // Reused decoded source for fast previews
  bool _previewScheduled = false;
  bool _previewDirty = false;
  late final SignatureImageProcessingService _svc;

  @override
  void initState() {
    super.initState();
    _aspectLocked = false; // Not persisted in GraphicAdjust
    _bgRemoval = widget.initialGraphicAdjust.bgRemoval;
    _contrast = widget.initialGraphicAdjust.contrast;
    _brightness = 1.0; // Changed from 0.0 to 1.0
    _rotation = widget.initialRotation;
    _processedBytes = widget.asset.bytes; // initial preview
    _svc = SignatureImageProcessingService();
    // Decode once for preview reuse
    // Note: package:image lives in service; expose decode via service
    _decodedSource = _svc.decode(widget.asset.bytes);
  }

  @override
  void dispose() {
    // Frame callbacks are tied to mounting; nothing to cancel explicitly
    super.dispose();
  }

  /// Update processed image bytes when processing parameters change.
  /// Coalesce rapid changes once per frame to keep UI responsive and tests stable.
  void _updateProcessedBytes() {
    _previewDirty = true;
    if (_previewScheduled) return;
    _previewScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previewScheduled = false;
      if (!mounted || !_previewDirty) return;
      _previewDirty = false;
      final adjust = domain.GraphicAdjust(
        contrast: _contrast,
        brightness: _brightness,
        bgRemoval: _bgRemoval,
      );
      // Fast preview path: reuse decoded, downscale, low-compression encode
      final decoded = _decodedSource;
      if (decoded != null) {
        final preview = _svc.processPreviewFromDecoded(decoded, adjust);
        if (mounted) setState(() => _processedBytes = preview);
      } else {
        // Fallback to repository path if decode failed
        final bytes = ref
            .read(signatureViewModelProvider)
            .getProcessedBytes(widget.asset, adjust);
        if (mounted) setState(() => _processedBytes = bytes);
      }
    });
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
