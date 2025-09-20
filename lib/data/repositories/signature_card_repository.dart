import 'package:image/image.dart' as img;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/model.dart';
import '../../data/services/signature_image_processing_service.dart';

class DisplaySignatureData {
  final img.Image image; // image to render (image-first path)
  final List<double>? colorMatrix; // optional GPU color matrix
  const DisplaySignatureData({required this.image, this.colorMatrix});
}

/// CachedSignatureCard wraps SignatureCard data and stores a processed cache.
class CachedSignatureCard {
  final SignatureAsset asset;
  final double rotationDeg;
  final GraphicAdjust graphicAdjust;

  img.Image? _cachedProcessedImage;

  CachedSignatureCard({
    required this.asset,
    required this.rotationDeg,
    this.graphicAdjust = const GraphicAdjust(),
    img.Image? initialProcessedImage,
  }) {
    if (initialProcessedImage != null) {
      _cachedProcessedImage = initialProcessedImage;
    }
  }

  // Intentionally no copyWith to avoid conflicting with Freezed interface

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

  factory CachedSignatureCard.fromPublic(SignatureCard card) =>
      CachedSignatureCard(
        asset: card.asset,
        rotationDeg: card.rotationDeg,
        graphicAdjust: card.graphicAdjust,
      );
}

class SignatureCardStateNotifier extends StateNotifier<List<SignatureCard>> {
  SignatureCardStateNotifier() : super(const []);

  // Internal storage with cache
  final List<CachedSignatureCard> _cards = <CachedSignatureCard>[];

  // Stateless image processing service used by this repository
  final SignatureImageProcessingService _processingService =
      SignatureImageProcessingService();

  void add(SignatureCard card) {
    _cards.add(CachedSignatureCard.fromPublic(card));
    _publish();
  }

  void addWithAsset(SignatureAsset asset, double rotationDeg) {
    _cards.add(CachedSignatureCard(asset: asset, rotationDeg: rotationDeg));
    _publish();
  }

  void update(
    SignatureCard card,
    double? rotationDeg,
    GraphicAdjust? graphicAdjust,
  ) {
    for (var i = 0; i < _cards.length; i++) {
      final c = _cards[i];
      final isSameCard =
          c.asset == card.asset &&
          c.rotationDeg == card.rotationDeg &&
          c.graphicAdjust == card.graphicAdjust;
      if (isSameCard) {
        final newRotation = rotationDeg ?? c.rotationDeg;
        final newAdjust = graphicAdjust ?? c.graphicAdjust;
        // Compute processed image for updated adjust
        final processedImage = _processingService.processImageToImage(
          c.asset.sigImage,
          newAdjust,
        );
        final next = CachedSignatureCard(
          asset: c.asset,
          rotationDeg: newRotation,
          graphicAdjust: newAdjust,
        );
        next.setProcessedImage(processedImage);
        _cards[i] = next;
        _publish();
        return;
      }
    }
  }

  void remove(SignatureCard card) {
    _cards.removeWhere(
      (c) =>
          c.asset == card.asset &&
          c.rotationDeg == card.rotationDeg &&
          c.graphicAdjust == card.graphicAdjust,
    );
    _publish();
  }

  void clearAll() {
    _cards.clear();
    state = const <SignatureCard>[];
  }

  /// New: Returns processed decoded image for the given asset + adjustments.
  img.Image getProcessedImage(SignatureAsset asset, GraphicAdjust adjust) {
    // Try to find a matching card by asset
    for (final c in _cards) {
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
    for (final c in _cards) {
      c.invalidateCache();
    }
  }

  /// Clears cached processed images for a specific asset only.
  void clearCacheForAsset(SignatureAsset asset) {
    for (final c in _cards) {
      if (c.asset == asset) {
        c.invalidateCache();
      }
    }
  }

  void _publish() {
    state = List<SignatureCard>.unmodifiable(
      _cards
          .map(
            (c) => SignatureCard(
              asset: c.asset,
              rotationDeg: c.rotationDeg,
              graphicAdjust: c.graphicAdjust,
            ),
          )
          .toList(growable: false),
    );
  }
}

final signatureCardRepositoryProvider =
    StateNotifierProvider<SignatureCardStateNotifier, List<SignatureCard>>(
      (ref) => SignatureCardStateNotifier(),
    );
