import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../../utils/rotation_utils.dart' as rot;

/// A lightweight widget to render signature bytes with rotation and an
/// angle-aware scale-to-fit so the rotated image stays within its bounds.
/// Don't use `decodeImage`, large images can be crazily slow, especially on web.
class RotatedSignatureImage extends StatefulWidget {
  const RotatedSignatureImage({
    super.key,
    required this.image,
    this.rotationDeg = 0.0, // counterclockwise as positive
    this.filterQuality = FilterQuality.low,
    this.semanticLabel,
    this.cacheWidth,
    this.cacheHeight,
  });

  /// Decoded CPU image (from `package:image`).
  final img.Image image;

  /// Rotation in degrees. Positive values rotate counterclockwise in math sense.
  /// Screen-space is handled via [rot.ccwRadians].
  final double rotationDeg;

  final FilterQuality filterQuality;

  final String? semanticLabel;

  /// Optional target size hints to reduce decode cost.
  /// If only one is provided, the other is computed to preserve aspect.
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  State<RotatedSignatureImage> createState() => _RotatedSignatureImageState();
}

class _RotatedSignatureImageState extends State<RotatedSignatureImage> {
  Uint8List? _encodedBytes; // PNG-encoded bytes for Image.memory
  img.Image? _lastSrc; // To detect changes cheaply
  int? _lastW;
  int? _lastH;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant RotatedSignatureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final srcChanged =
        !identical(widget.image, _lastSrc) ||
        widget.image.width != (oldWidget.image.width) ||
        widget.image.height != (oldWidget.image.height);
    final sizeHintChanged =
        widget.cacheWidth != oldWidget.cacheWidth ||
        widget.cacheHeight != oldWidget.cacheHeight;
    if (srcChanged || sizeHintChanged) {
      _prepare();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _prepare() async {
    final src = widget.image;
    _lastSrc = src;

    // Compute target decode size preserving aspect if hints provided.
    int targetW = src.width;
    int targetH = src.height;
    if (widget.cacheWidth != null || widget.cacheHeight != null) {
      if (widget.cacheWidth != null && widget.cacheHeight != null) {
        targetW = widget.cacheWidth!.clamp(1, src.width);
        targetH = widget.cacheHeight!.clamp(1, src.height);
      } else if (widget.cacheWidth != null) {
        targetW = widget.cacheWidth!.clamp(1, src.width);
        targetH = (targetW * src.height / src.width).round().clamp(
          1,
          src.height,
        );
      } else if (widget.cacheHeight != null) {
        targetH = widget.cacheHeight!.clamp(1, src.height);
        targetW = (targetH * src.width / src.height).round().clamp(
          1,
          src.width,
        );
      }
    }

    img.Image working = src;
    if (working.width != targetW || working.height != targetH) {
      // High-quality resize; image package chooses a reasonable default.
      working = img.copyResize(working, width: targetW, height: targetH);
    }

    // Ensure RGBA (4 channels) so alpha is preserved when encoding.
    working = working.convert(numChannels: 4);

    _lastW = working.width;
    _lastH = working.height;

    // Encode to PNG with low compression level for faster encode.
    // This avoids manual decode in the widget; Flutter will decode the PNG.
    final pngEncoder = img.PngEncoder(level: 1);
    final bytes = Uint8List.fromList(pngEncoder.encode(working));
    if (!mounted) return;
    setState(() => _encodedBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    // Compute angle-aware scale so rotated image stays within bounds.
    final double angleRad = rot.ccwRadians(widget.rotationDeg);
    final double ar =
        widget.image.width == 0
            ? 1.0
            : widget.image.width / widget.image.height;
    final double k = rot.scaleToFitForAngle(angleRad, ar: ar);

    Widget core =
        _encodedBytes == null
            ? const SizedBox.shrink()
            : Image.memory(
              _encodedBytes!,
              fit: BoxFit.contain,
              filterQuality: widget.filterQuality,
              gaplessPlayback: true,
            );
    if (widget.semanticLabel != null) {
      core = Semantics(label: widget.semanticLabel, child: core);
    }

    // Order: scale first, then rotate. Scale ensures rotated bounds fit.
    Widget transformed = Transform.scale(
      scale: k,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: angleRad,
        alignment: Alignment.center,
        child: core,
      ),
    );

    // Allow parent to size; we simply contain within available space.
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: SizedBox(
        width: _lastW?.toDouble() ?? widget.image.width.toDouble(),
        height: _lastH?.toDouble() ?? widget.image.height.toDouble(),
        child: transformed,
      ),
    );
  }
}
