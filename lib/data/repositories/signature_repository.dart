import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../domain/models/model.dart';
import 'pdf_repository.dart';

class SignatureController extends StateNotifier<SignatureCard> {
  final Ref ref;
  SignatureController(this.ref) : super(SignatureCard.initial());
  static const Size pageSize = Size(400, 560);

  void resetForNewPage() {
    state = SignatureCard.initial();
    ref.read(currentRectProvider.notifier).setRect(null);
    ref.read(editingEnabledProvider.notifier).set(false);
  }

  @visibleForTesting
  void placeDefaultRect() {
    final w = 120.0, h = 60.0;
    final rand = Random();
    // Generate a center within 10%..90% of each axis to reduce off-screen risk
    final cx = pageSize.width * (0.1 + rand.nextDouble() * 0.8);
    final cy = pageSize.height * (0.1 + rand.nextDouble() * 0.8);
    Rect r = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    r = _clampRectToPage(r);
    ref.read(currentRectProvider.notifier).setRect(r);
    ref.read(editingEnabledProvider.notifier).set(true);
  }

  void loadSample() {
    final w = 120.0, h = 60.0;
    ref
        .read(currentRectProvider.notifier)
        .setRect(
          Rect.fromCenter(
            center: Offset(pageSize.width / 2, pageSize.height * 0.75),
            width: w,
            height: h,
          ),
        );
    ref.read(editingEnabledProvider.notifier).set(true);
  }

  void setInvalidSelected(BuildContext context) {
    // Fallback message without localization to keep core logic testable
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.of<AppLocalizations>(
            context,
            AppLocalizations,
          )!.invalidOrUnsupportedFile,
        ),
      ),
    );
  }

  void drag(Offset delta) {
    final currentRect = ref.read(currentRectProvider);
    if (currentRect == null || !ref.read(editingEnabledProvider)) return;
    final moved = currentRect.shift(delta);
    ref.read(currentRectProvider.notifier).setRect(_clampRectToPage(moved));
  }

  void resize(Offset delta) {
    final currentRect = ref.read(currentRectProvider);
    if (currentRect == null || !ref.read(editingEnabledProvider)) return;
    final r = currentRect;
    double newW = r.width + delta.dx;
    double newH = r.height + delta.dy;
    if (ref.read(aspectLockedProvider)) {
      final aspect = r.width / r.height;
      // Keep ratio based on the dominant proportional delta
      final dxRel = (delta.dx / r.width).abs();
      final dyRel = (delta.dy / r.height).abs();
      if (dxRel >= dyRel) {
        newW = newW.clamp(20.0, double.infinity);
        newH = newW / aspect;
      } else {
        newH = newH.clamp(20.0, double.infinity);
        newW = newH * aspect;
      }
      // Scale down to fit within page bounds while preserving ratio
      final scaleW = pageSize.width / newW;
      final scaleH = pageSize.height / newH;
      final scale = math.min(1.0, math.min(scaleW, scaleH));
      newW *= scale;
      newH *= scale;
      // Ensure minimum size of 20x20, scaling up proportionally if needed
      final minScale = math.max(1.0, math.max(20.0 / newW, 20.0 / newH));
      newW *= minScale;
      newH *= minScale;
      Rect resized = Rect.fromLTWH(r.left, r.top, newW, newH);
      resized = _clampRectPositionToPage(resized);
      ref.read(currentRectProvider.notifier).setRect(resized);
      return;
    }
    // Unlocked aspect: clamp each dimension independently
    newW = newW.clamp(20.0, pageSize.width);
    newH = newH.clamp(20.0, pageSize.height);
    Rect resized = Rect.fromLTWH(r.left, r.top, newW, newH);
    resized = _clampRectToPage(resized);
    ref.read(currentRectProvider.notifier).setRect(resized);
  }

  Rect _clampRectToPage(Rect r) {
    // Ensure size never exceeds page bounds first, to avoid invalid clamp ranges
    final double w = r.width.clamp(20.0, pageSize.width);
    final double h = r.height.clamp(20.0, pageSize.height);
    final double left = r.left.clamp(0.0, pageSize.width - w);
    final double top = r.top.clamp(0.0, pageSize.height - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  Rect _clampRectPositionToPage(Rect r) {
    final double left = r.left.clamp(0.0, pageSize.width - r.width);
    final double top = r.top.clamp(0.0, pageSize.height - r.height);
    return Rect.fromLTWH(left, top, r.width, r.height);
  }

  void toggleAspect(bool v) => ref.read(aspectLockedProvider.notifier).set(v);
  void setBgRemoval(bool v) =>
      state = state.copyWith(
        graphicAdjust: state.graphicAdjust.copyWith(bgRemoval: v),
      );
  void setContrast(double v) =>
      state = state.copyWith(
        graphicAdjust: state.graphicAdjust.copyWith(contrast: v),
      );
  void setBrightness(double v) =>
      state = state.copyWith(
        graphicAdjust: state.graphicAdjust.copyWith(brightness: v),
      );
  void setRotation(double deg) => state = state.copyWith(rotationDeg: deg);

  void ensureRectForStrokes() {
    if (ref.read(currentRectProvider) == null) {
      ref
          .read(currentRectProvider.notifier)
          .setRect(
            Rect.fromCenter(
              center: Offset(pageSize.width / 2, pageSize.height * 0.75),
              width: 140,
              height: 70,
            ),
          );
      ref.read(editingEnabledProvider.notifier).set(true);
    }
  }

  void setImageBytes(Uint8List bytes) {
    final newAsset = SignatureAsset(id: 'drawn', bytes: bytes);
    state = state.copyWith(asset: newAsset);
    if (ref.read(currentRectProvider) == null) {
      placeDefaultRect();
    }
    ref.read(editingEnabledProvider.notifier).set(true);
  }

  // Select image from the shared signature library
  void setImageFromLibrary({required SignatureAsset asset}) {
    state = state.copyWith(asset: asset);
    if (ref.read(currentRectProvider) == null) {
      placeDefaultRect();
    }
    ref.read(editingEnabledProvider.notifier).set(true);
  }

  void clearImage() {
    state = SignatureCard.initial();
    ref.read(currentRectProvider.notifier).setRect(null);
    ref.read(editingEnabledProvider.notifier).set(false);
  }

  void placeAtCenter(Offset center, {double width = 120, double height = 60}) {
    Rect r = Rect.fromCenter(center: center, width: width, height: height);
    r = _clampRectToPage(r);
    ref.read(currentRectProvider.notifier).setRect(r);
    ref.read(editingEnabledProvider.notifier).set(true);
  }

  // Confirm current signature: freeze editing and place it on the PDF as an immutable overlay.
  // Stores the placement rect in UI-space (SignatureController.pageSize units).
  // Returns the Rect placed, or null if no rect to confirm.
  Rect? confirmCurrentSignature(WidgetRef ref) {
    final r = ref.read(currentRectProvider);
    if (r == null) return null;
    // Place onto the current page
    final pdf = ref.read(documentRepositoryProvider);
    if (!pdf.loaded) return null;
    ref
        .read(documentRepositoryProvider.notifier)
        .addPlacement(
          page: pdf.currentPage,
          rect: r,
          asset: state.asset,
          rotationDeg: state.rotationDeg,
        );
    // Newly placed index is the last one on the page
    final idx =
        (ref
                .read(documentRepositoryProvider)
                .placementsByPage[pdf.currentPage]
                ?.length ??
            1) -
        1;
    // Auto-select the newly placed item so the red box appears
    if (idx >= 0) {
      ref.read(documentRepositoryProvider.notifier).selectPlacement(idx);
    }
    // Freeze editing: keep rect for preview but disable interaction
    ref.read(editingEnabledProvider.notifier).set(false);
    return r;
  }

  // Test/helper variant: confirm using a ProviderContainer instead of WidgetRef.
  // Useful in widget tests where obtaining a WidgetRef is not straightforward.
  @visibleForTesting
  Rect? confirmCurrentSignatureWithContainer(ProviderContainer container) {
    final r = container.read(currentRectProvider);
    if (r == null) return null;
    final pdf = container.read(documentRepositoryProvider);
    if (!pdf.loaded) return null;
    container
        .read(documentRepositoryProvider.notifier)
        .addPlacement(
          page: pdf.currentPage,
          rect: r,
          asset: state.asset,
          rotationDeg: state.rotationDeg,
        );
    final idx =
        (container
                .read(documentRepositoryProvider)
                .placementsByPage[pdf.currentPage]
                ?.length ??
            1) -
        1;
    // Auto-select the newly placed item so the red box appears
    if (idx >= 0) {
      container.read(documentRepositoryProvider.notifier).selectPlacement(idx);
    }
    // Freeze editing: keep rect for preview but disable interaction
    container.read(editingEnabledProvider.notifier).set(false);
    return r;
  }

  // Remove the active overlay (draft or confirmed preview) but keep image settings intact
  void clearActiveOverlay() {
    ref.read(currentRectProvider.notifier).setRect(null);
    ref.read(editingEnabledProvider.notifier).set(false);
  }
}

final signatureCardProvider =
    StateNotifierProvider<SignatureController, SignatureCard>(
      (ref) => SignatureController(ref),
    );

final currentRectProvider = StateNotifierProvider<RectNotifier, Rect?>(
  (ref) => RectNotifier(),
);

class RectNotifier extends StateNotifier<Rect?> {
  RectNotifier() : super(null);

  void setRect(Rect? r) => state = r;
}

final editingEnabledProvider = StateNotifierProvider<BoolNotifier, bool>(
  (ref) => BoolNotifier(false),
);

class BoolNotifier extends StateNotifier<bool> {
  BoolNotifier(bool initial) : super(initial);

  void set(bool v) => state = v;
}

final aspectLockedProvider = StateNotifierProvider<BoolNotifier, bool>(
  (ref) => BoolNotifier(false),
);

/// Derived provider that returns processed signature image bytes according to
/// current adjustment settings (contrast/brightness) and background removal.
/// Returns null if no image is loaded. The output is a PNG to preserve alpha.
final processedSignatureImageProvider = Provider<Uint8List?>((ref) {
  final SignatureAsset asset = ref.watch(
    signatureCardProvider.select((s) => s.asset),
  );
  final double contrast = ref.watch(
    signatureCardProvider.select((s) => s.graphicAdjust.contrast),
  );
  final double brightness = ref.watch(
    signatureCardProvider.select((s) => s.graphicAdjust.brightness),
  );
  final bool bgRemoval = ref.watch(
    signatureCardProvider.select((s) => s.graphicAdjust.bgRemoval),
  );

  Uint8List? bytes = asset.bytes;
  if (bytes.isEmpty) return null;

  // Decode (supports PNG/JPEG, etc.)
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  // Work on a copy and ensure an alpha channel is present (RGBA)
  var out = decoded.clone();
  if (out.hasPalette || !out.hasAlpha) {
    // Force truecolor RGBA image so per-pixel alpha writes take effect
    out = out.convert(numChannels: 4);
  }

  // Parameters
  // Rotation is not applied here (UI uses Transform; export applies once).
  const int thrLow = 220; // begin soft transparency from this avg luminance
  const int thrHigh = 245; // fully transparent from this avg luminance

  // Helper to clamp int
  int clamp255(num v) => v.clamp(0, 255).toInt();

  // Iterate pixels
  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      final p = out.getPixel(x, y);
      int a = clamp255(p.aNormalized * 255.0);
      int r = clamp255(p.rNormalized * 255.0);
      int g = clamp255(p.gNormalized * 255.0);
      int b = clamp255(p.bNormalized * 255.0);

      // Apply contrast/brightness in sRGB space
      // new = (old-128)*contrast + 128 + brightness*255
      final double brOffset = brightness * 255.0;
      r = clamp255((r - 128) * contrast + 128 + brOffset);
      g = clamp255((g - 128) * contrast + 128 + brOffset);
      b = clamp255((b - 128) * contrast + 128 + brOffset);

      // Near-white background removal (compute average luminance)
      final int avg = ((r + g + b) / 3).round();
      int remAlpha = 255; // 255 = fully opaque, 0 = transparent
      if (bgRemoval) {
        if (avg >= thrHigh) {
          remAlpha = 0;
        } else if (avg >= thrLow) {
          // Soft fade between thrLow..thrHigh
          final double t = (avg - thrLow) / (thrHigh - thrLow);
          remAlpha = clamp255(255 * (1.0 - t));
        } else {
          remAlpha = 255;
        }
      }

      // Combine with existing alpha (preserve existing transparency)
      final newA = math.min(a, remAlpha);

      out.setPixelRgba(x, y, r, g, b, newA);
    }
  }

  // NOTE: Do not rotate here to keep UI responsive while dragging the slider.
  // Rotation is applied in the UI using Transform.rotate for preview and
  // performed once on confirm/export to avoid per-frame recomputation.

  // Encode as PNG to preserve transparency
  final png = img.encodePng(out, level: 6);
  return Uint8List.fromList(png);
});
