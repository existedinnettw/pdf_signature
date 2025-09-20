import 'package:image/image.dart' as img;

/// Removes near-white background by making pixels with high RGB values transparent.
///
/// - Ensures the image has an alpha channel (RGBA) before modification.
/// - Returns a new img.Image instance; does not mutate the input reference.
/// - threshold: 0..255; pixels with r,g,b >= threshold become fully transparent.
img.Image removeNearWhiteBackground(img.Image image, {int threshold = 240}) {
  // Ensure truecolor RGBA; paletted images won't apply per-pixel alpha properly.
  final hadAlpha = image.hasAlpha;
  img.Image out =
      (image.hasPalette || !image.hasAlpha)
          ? image.convert(numChannels: 4)
          : img.Image.from(image);

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);
      final r = p.r;
      final g = p.g;
      final b = p.b;
      if (r >= threshold && g >= threshold && b >= threshold) {
        out.setPixelRgba(x, y, r, g, b, 0);
      } else {
        // Keep original alpha if input had alpha; otherwise force fully opaque.
        final a = hadAlpha ? p.a : 255;
        if (p.a != a) {
          out.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }
  }
  return out;
}
