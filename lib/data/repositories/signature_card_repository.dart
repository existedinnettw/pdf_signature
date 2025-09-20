import 'package:image/image.dart' as img;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/model.dart';
import '../../data/services/signature_image_processing_service.dart';

class DisplaySignatureData {
  final img.Image image; // image to render (image-first path)
  final List<double>? colorMatrix; // optional GPU color matrix
  const DisplaySignatureData({required this.image, this.colorMatrix});
}

/// CachedSignatureCard extends SignatureCard with an internal processed cache
class CachedSignatureCard extends SignatureCard {
  img.Image? _cachedProcessedImage;

  CachedSignatureCard({
    required super.asset,
    required super.rotationDeg,
    super.graphicAdjust,
    img.Image? initialProcessedImage,
  }) {
    // Seed cache if provided
    if (initialProcessedImage != null) {
      _cachedProcessedImage = initialProcessedImage;
    }
  }

  /// Invalidate the cached processed image, forcing recompute next time.
  void invalidateCache() {
    _cachedProcessedImage = null;
  }

  /// Sets/updates the processed image explicitly (used after adjustments update)
  void setProcessedImage(img.Image image) {
    _cachedProcessedImage = image;
  }

  factory CachedSignatureCard.initial() => CachedSignatureCard(
    asset: SignatureCard.initial().asset,
    rotationDeg: SignatureCard.initial().rotationDeg,
    graphicAdjust: SignatureCard.initial().graphicAdjust,
  );
}

class SignatureCardStateNotifier
    extends StateNotifier<List<CachedSignatureCard>> {
  SignatureCardStateNotifier() : super(const []) {
    state = const <CachedSignatureCard>[];
  }

  // Stateless image processing service used by this repository
  final SignatureImageProcessingService _processingService =
      SignatureImageProcessingService();

  void add(SignatureCard card) {
    final wrapped =
        card is CachedSignatureCard
            ? card
            : CachedSignatureCard(
              asset: card.asset,
              rotationDeg: card.rotationDeg,
              graphicAdjust: card.graphicAdjust,
            );
    final next = List<CachedSignatureCard>.of(state)..add(wrapped);
    state = List<CachedSignatureCard>.unmodifiable(next);
  }

  void addWithAsset(SignatureAsset asset, double rotationDeg) {
    final next = List<CachedSignatureCard>.of(state)
      ..add(CachedSignatureCard(asset: asset, rotationDeg: rotationDeg));
    state = List<CachedSignatureCard>.unmodifiable(next);
  }

  void update(
    SignatureCard card,
    double? rotationDeg,
    GraphicAdjust? graphicAdjust,
  ) {
    final list = List<CachedSignatureCard>.of(state);
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c == card) {
        final updated = c.copyWith(
          rotationDeg: rotationDeg ?? c.rotationDeg,
          graphicAdjust: graphicAdjust ?? c.graphicAdjust,
        );
        // Compute and set the single processed bytes for the updated adjust
        final processedImage = _processingService.processImageToImage(
          updated.asset.sigImage,
          updated.graphicAdjust,
        );
        final next = CachedSignatureCard(
          asset: updated.asset,
          rotationDeg: updated.rotationDeg,
          graphicAdjust: updated.graphicAdjust,
        );
        next.setProcessedImage(processedImage);
        list[i] = next;
        state = List<CachedSignatureCard>.unmodifiable(list);
        return;
      }
    }
  }

  void remove(SignatureCard card) {
    state = List<CachedSignatureCard>.unmodifiable(
      state.where((c) => c != card).toList(growable: false),
    );
  }

  void clearAll() {
    state = const <CachedSignatureCard>[];
  }

  /// New: Returns processed decoded image for the given asset + adjustments.
  img.Image getProcessedImage(SignatureAsset asset, GraphicAdjust adjust) {
    // Try to find a matching card by asset
    for (final c in state) {
      if (c.asset == asset) {
        if (c.graphicAdjust == adjust) {
          // If cached bytes exist, decode once; otherwise compute from image
          if (c._cachedProcessedImage != null) {
            return c._cachedProcessedImage!;
          }
          return _processingService.processImageToImage(
            c.asset.sigImage,
            c.graphicAdjust,
          );
        }
        // Previewing unsaved adjustments: compute from image without caching
        return _processingService.processImageToImage(asset.sigImage, adjust);
      }
    }
    // Asset not found among cards (e.g., preview in dialog): compute on-the-fly
    return _processingService.processImageToImage(asset.sigImage, adjust);
  }

  /// Provide display data optimized: if bgRemoval false, returns original image + matrix;
  /// if bgRemoval true, returns processed image with baked adjustments and null matrix.
  DisplaySignatureData getDisplayData(
    SignatureAsset asset,
    GraphicAdjust adjust,
  ) {
    if (!adjust.bgRemoval) {
      // No CPU processing. Return original image + matrix for consumers.
      final matrix = _processingService.buildColorMatrix(adjust);
      return DisplaySignatureData(image: asset.sigImage, colorMatrix: matrix);
    }
    // bgRemoval path: provide processed image with baked adjustments.
    final processed = getProcessedImage(asset, adjust);
    return DisplaySignatureData(image: processed, colorMatrix: null);
  }

  /// New: Provide display image optimized for UI widgets that can accept img.Image.
  /// If bgRemoval is false, returns original image and a GPU color matrix.
  /// If bgRemoval is true, returns processed image with baked adjustments and null matrix.
  (img.Image image, List<double>? colorMatrix) getDisplayImage(
    SignatureAsset asset,
    GraphicAdjust adjust,
  ) {
    if (!adjust.bgRemoval) {
      final matrix = _processingService.buildColorMatrix(adjust);
      return (asset.sigImage, matrix);
    }
    final processed = getProcessedImage(asset, adjust);
    return (processed, null);
  }

  /// Clears all cached processed images.
  void clearProcessedCache() {
    for (final c in state) {
      c.invalidateCache();
    }
  }

  /// Clears cached processed images for a specific asset only.
  void clearCacheForAsset(SignatureAsset asset) {
    for (final c in state) {
      if (c.asset == asset) {
        c.invalidateCache();
      }
    }
  }
}

final signatureCardRepositoryProvider = StateNotifierProvider<
  SignatureCardStateNotifier,
  List<CachedSignatureCard>
>((ref) => SignatureCardStateNotifier());
