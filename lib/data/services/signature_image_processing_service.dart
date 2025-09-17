import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../domain/models/model.dart' as domain;

/// Service for processing signature images with graphic adjustments
class SignatureImageProcessingService {
  /// Decode image bytes once and reuse the decoded image for preview processing.
  img.Image? decode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Process image bytes with the given graphic adjustments
  Uint8List processImage(Uint8List bytes, domain.GraphicAdjust adjust) {
    if (adjust.contrast == 1.0 &&
        adjust.brightness == 0.0 &&
        !adjust.bgRemoval) {
      return bytes; // No processing needed
    }
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        img.Image processed = decoded;

        // Apply contrast and brightness first
        if (adjust.contrast != 1.0 || adjust.brightness != 0.0) {
          processed = img.adjustColor(
            processed,
            contrast: adjust.contrast,
            brightness: adjust.brightness,
          );
        }

        // Apply background removal after color adjustments
        if (adjust.bgRemoval) {
          processed = _removeBackground(processed);
        }

        // Encode back to PNG to preserve transparency
        return Uint8List.fromList(img.encodePng(processed));
      } else {
        return bytes;
      }
    } catch (e) {
      // If processing fails, return original bytes
      return bytes;
    }
  }

  /// Fast preview processing:
  /// - Reuses a decoded image
  /// - Downscales to a small size for UI preview
  /// - Uses low-compression PNG to reduce CPU cost
  Uint8List processPreviewFromDecoded(
    img.Image decoded,
    domain.GraphicAdjust adjust, {
    int maxDimension = 256,
  }) {
    try {
      // Create a small working copy for quick adjustments
      final int w = decoded.width;
      final int h = decoded.height;
      final double scale = (w > h ? maxDimension / w : maxDimension / h).clamp(
        0.0,
        1.0,
      );
      img.Image work =
          (scale < 1.0)
              ? img.copyResize(decoded, width: (w * scale).round())
              : img.Image.from(decoded);

      // Apply contrast and brightness
      if (adjust.contrast != 1.0 || adjust.brightness != 0.0) {
        work = img.adjustColor(
          work,
          contrast: adjust.contrast,
          brightness: adjust.brightness,
        );
      }

      // Background removal on downscaled image for speed
      if (adjust.bgRemoval) {
        work = _removeBackground(work);
      }

      // Encode with low compression (level 0) for speed
      return Uint8List.fromList(img.encodePng(work, level: 0));
    } catch (_) {
      // Fall back to original size path if something goes wrong
      return processImage(
        Uint8List.fromList(img.encodePng(decoded, level: 0)),
        adjust,
      );
    }
  }

  /// Remove near-white background using simple threshold approach for maximum speed
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
          result.setPixel(
            x,
            y,
            img.ColorRgba8(r.toInt(), g.toInt(), b.toInt(), 0),
          );
        }
      }
    }
    return result;
  }
}
