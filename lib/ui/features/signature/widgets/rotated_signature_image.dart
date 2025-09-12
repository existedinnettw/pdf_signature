import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// A lightweight widget to render signature bytes with rotation and an
/// angle-aware scale-to-fit so the rotated image stays within its bounds.
class RotatedSignatureImage extends StatefulWidget {
  const RotatedSignatureImage({
    super.key,
    required this.bytes,
    this.rotationDeg = 0.0,
    this.filterQuality = FilterQuality.low,
    this.semanticLabel,
  });

  final Uint8List bytes;
  final double rotationDeg;
  final FilterQuality filterQuality;
  final BoxFit fit = BoxFit.contain;
  final bool gaplessPlayback = true;
  final Alignment alignment = Alignment.center;
  final bool wrapInRepaintBoundary = true;
  final String? semanticLabel;

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

  void _setAspectRatio(double ar) {
    if (mounted && _derivedAspectRatio != ar) {
      setState(() => _derivedAspectRatio = ar);
    }
  }

  void _resolveImage() {
    _unlisten();
    // Decode synchronously to get aspect ratio
    // Guard against empty / invalid bytes that some simplified tests may inject.
    if (widget.bytes.isEmpty) {
      _setAspectRatio(1.0); // assume square to avoid layout exceptions
      return;
    }
    try {
      final decoded = img.decodePng(widget.bytes);
      if (decoded != null) {
        final w = decoded.width;
        final h = decoded.height;
        if (w > 0 && h > 0) {
          _setAspectRatio(w / h);
        }
      }
    } catch (_) {
      // Swallow decode errors for test-provided dummy data; assume square.
      _setAspectRatio(1.0);
    }
    final stream = _provider.resolve(createLocalImageConfiguration(context));
    _stream = stream;
    _listener = ImageStreamListener((ImageInfo info, bool sync) {
      final w = info.image.width;
      final h = info.image.height;
      if (w > 0 && h > 0) {
        _setAspectRatio(w / h);
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
      errorBuilder: (context, error, stackTrace) {
        // Return a placeholder for invalid images
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );

    if (angle != 0.0) {
      final double c = math.cos(angle).abs();
      final double s = math.sin(angle).abs();
      final ar = _derivedAspectRatio;
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
    }

    if (!widget.wrapInRepaintBoundary) return img;
    return RepaintBoundary(child: img);
  }
}
