import 'package:image/image.dart' as img;
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/addons.dart';
import '../../domain/models/model.dart' as domain;
import '../../utils/background_removal.dart' as br;

/// Service for processing signature images with graphic adjustments
class SignatureImageProcessingService {
  /// Build a GPU color matrix (brightness/contrast) using colorfilter_generator.
  /// Domain neutral value is 1.0; addon neutral is 0. Map by (value-1.0).
  List<double>? buildColorMatrix(domain.GraphicAdjust adjust) {
    final bAddon = adjust.brightness - 1.0;
    final cAddon = adjust.contrast - 1.0;
    if (bAddon == 0 && cAddon == 0) return null; // identity
    final gen = ColorFilterGenerator(
      name: 'signature_adjust',
      filters: [
        if (bAddon != 0) ColorFilterAddons.brightness(bAddon),
        if (cAddon != 0) ColorFilterAddons.contrast(cAddon),
      ],
    );
    return gen.matrix;
  }

  /// Process an already decoded image and return a new decoded image.
  img.Image processImageToImage(img.Image image, domain.GraphicAdjust adjust) {
    img.Image processed = img.Image.from(image);

    // Apply contrast and brightness first (domain neutral is 1.0)
    if (adjust.contrast != 1.0 || adjust.brightness != 1.0) {
      // performance actually bad due to dual forloops internally
      processed = img.adjustColor(
        processed,
        contrast: adjust.contrast,
        brightness: adjust.brightness,
      );
    }

    // Apply background removal after color adjustments
    if (adjust.bgRemoval) {
      processed = br.removeNearWhiteBackground(processed, threshold: 240);
    }

    return processed;
  }

  // Background removal implemented in utils/background_removal.dart
}
