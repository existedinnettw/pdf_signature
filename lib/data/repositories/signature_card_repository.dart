import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/model.dart';
import '../../data/services/signature_image_processing_service.dart';

/// CachedSignatureCard extends SignatureCard with an internal processed cache
class CachedSignatureCard extends SignatureCard {
  Uint8List? _cachedProcessed;

  CachedSignatureCard({
    required super.asset,
    required super.rotationDeg,
    super.graphicAdjust,
    Uint8List? initialProcessed,
  });

  /// Returns cached processed bytes for the current [graphicAdjust], computing
  /// via [service] if not cached yet.
  Uint8List getOrComputeProcessed(SignatureImageProcessingService service) {
    final existing = _cachedProcessed;
    if (existing != null) return existing;
    final computed = service.processImage(asset.bytes, graphicAdjust);
    _cachedProcessed = computed;
    return computed;
  }

  /// Invalidate the cached processed bytes, forcing recompute next time.
  void invalidateCache() {
    _cachedProcessed = null;
  }

  /// Sets/updates the processed bytes explicitly (used after adjustments update)
  void setProcessed(Uint8List bytes) {
    _cachedProcessed = bytes;
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
        final processed = _processingService.processImage(
          updated.asset.bytes,
          updated.graphicAdjust,
        );
        final next = CachedSignatureCard(
          asset: updated.asset,
          rotationDeg: updated.rotationDeg,
          graphicAdjust: updated.graphicAdjust,
        );
        next.setProcessed(processed);
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

  /// Returns processed image bytes for the given asset + adjustments.
  /// Uses an internal cache to avoid re-processing.
  Uint8List getProcessedBytes(SignatureAsset asset, GraphicAdjust adjust) {
    // Try to find a matching card by asset
    for (final c in state) {
      if (c.asset == asset) {
        // If requested adjust equals the card's current adjust, use per-card cache
        if (c.graphicAdjust == adjust) {
          return c.getOrComputeProcessed(_processingService);
        }
        // Previewing unsaved adjustments: compute without caching
        return _processingService.processImage(asset.bytes, adjust);
      }
    }
    // Asset not found among cards (e.g., preview in dialog): compute on-the-fly
    return _processingService.processImage(asset.bytes, adjust);
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
