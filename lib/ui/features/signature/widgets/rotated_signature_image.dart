import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../../utils/rotation_utils.dart' as rot;

/// A lightweight widget to render signature bytes with rotation and an
/// angle-aware scale-to-fit so the rotated image stays within its bounds.
class RotatedSignatureImage extends StatefulWidget {
  const RotatedSignatureImage({
    super.key,
    required this.bytes,
    this.rotationDeg = 0.0, // counterclockwise as positive
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

  MemoryImage get _provider {
    return MemoryImage(widget.bytes);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant RotatedSignatureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-resolve when the bytes change. Rotation does not affect
    // intrinsic aspect ratio, so avoid expensive decode/resolve on slider drags.
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
    // Resolve via ImageProvider; when first frame arrives, capture intrinsic size.
    // Avoid synchronous decode on UI thread to keep rotation smooth.
    if (widget.bytes.isEmpty) {
      _setAspectRatio(1.0); // safe fallback
      return;
    }
    // One-time synchronous header decode to establish aspect ratio quickly.
    // This only runs when bytes change (not on rotation), so it's acceptable.
    try {
      final decoded = img.decodeImage(widget.bytes);
      if (decoded != null && decoded.width > 0 && decoded.height > 0) {
        _setAspectRatio(decoded.width / decoded.height);
      }
    } catch (_) {
      // ignore decode errors and rely on image stream listener
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
    final angle = rot.ccwRadians(widget.rotationDeg);
    Widget img = Image.memory(
      widget.bytes,
      fit: widget.fit,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
      alignment: widget.alignment,
      semanticLabel: widget.semanticLabel,
      isAntiAlias: false,
      errorBuilder: (context, error, stackTrace) {
        // Return a placeholder for invalid images
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );

    if (angle != 0.0) {
      final scaleToFit = rot.scaleToFitForAngle(angle, ar: _derivedAspectRatio);
      img = Transform.scale(
        scale: scaleToFit,
        child: Transform.rotate(angle: angle, child: img),
      );
    }

    if (!widget.wrapInRepaintBoundary) return img;
    return RepaintBoundary(child: img);
  }
}
