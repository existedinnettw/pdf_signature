import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A lightweight widget to render signature bytes with rotation and an
/// angle-aware scale-to-fit so the rotated image stays within its bounds.
class RotatedSignatureImage extends StatefulWidget {
  const RotatedSignatureImage({
    super.key,
    required this.bytes,
    this.rotationDeg = 0.0,
    this.enableAngleAwareScale = true,
    this.fit = BoxFit.contain,
    this.gaplessPlayback = true,
    this.filterQuality = FilterQuality.low,
    this.wrapInRepaintBoundary = true,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.intrinsicAspectRatio,
  });

  final Uint8List bytes;
  final double rotationDeg;
  final bool enableAngleAwareScale;
  final BoxFit fit;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final bool wrapInRepaintBoundary;
  final AlignmentGeometry alignment;
  final String? semanticLabel;
  // Optional: intrinsic aspect ratio (width / height). If provided, we compute
  // an angle-aware scale for non-square images to ensure the rotated rectangle
  // (W,H) fits back into its (W,H) bounds. If null, we attempt to derive it
  // from the image stream; only fall back to the square heuristic if unknown.
  final double? intrinsicAspectRatio;

  @override
  State<RotatedSignatureImage> createState() => _RotatedSignatureImageState();
}

class _RotatedSignatureImageState extends State<RotatedSignatureImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _derivedAspectRatio; // width / height

  MemoryImage get _provider => MemoryImage(widget.bytes);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant RotatedSignatureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _derivedAspectRatio = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    _unlisten();
    // Only derive AR if not provided
    if (widget.intrinsicAspectRatio != null) return;
    final stream = _provider.resolve(createLocalImageConfiguration(context));
    _stream = stream;
    _listener = ImageStreamListener((ImageInfo info, bool sync) {
      final w = info.image.width;
      final h = info.image.height;
      if (w > 0 && h > 0) {
        final ar = w / h;
        if (mounted && _derivedAspectRatio != ar) {
          setState(() => _derivedAspectRatio = ar);
        }
      }
    });
    stream.addListener(_listener!);
  }

  void _unlisten() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _unlisten();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = widget.rotationDeg * math.pi / 180.0;
    Widget img = Image.memory(
      widget.bytes,
      fit: widget.fit,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
      alignment: widget.alignment,
      semanticLabel: widget.semanticLabel,
    );

    if (angle != 0.0) {
      if (widget.enableAngleAwareScale) {
        final double c = math.cos(angle).abs();
        final double s = math.sin(angle).abs();
        final ar = widget.intrinsicAspectRatio ?? _derivedAspectRatio;
        double scaleToFit;
        if (ar != null && ar > 0) {
          scaleToFit = math.min(ar / (ar * c + s), 1.0 / (ar * s + c));
        } else {
          // Fallback: square approximation
          scaleToFit = 1.0 / (c + s).clamp(1.0, double.infinity);
        }
        img = Transform.scale(
          scale: scaleToFit,
          child: Transform.rotate(angle: angle, child: img),
        );
      } else {
        img = Transform.rotate(angle: angle, child: img);
      }
    }

    if (!widget.wrapInRepaintBoundary) return img;
    return RepaintBoundary(child: img);
  }
}
