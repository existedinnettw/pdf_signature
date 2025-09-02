import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../../data/model/model.dart';

class PdfController extends StateNotifier<PdfState> {
  PdfController() : super(PdfState.initial());
  static const int samplePageCount = 5;

  void openSample() {
    state = state.copyWith(
      loaded: true,
      pageCount: samplePageCount,
      currentPage: 1,
      pickedPdfPath: null,
      signedPage: null,
      placementsByPage: {},
      placementImageByPage: {},
      selectedPlacementIndex: null,
    );
  }

  void openPicked({
    required String path,
    int pageCount = samplePageCount,
    Uint8List? bytes,
  }) {
    state = state.copyWith(
      loaded: true,
      pageCount: pageCount,
      currentPage: 1,
      pickedPdfPath: path,
      pickedPdfBytes: bytes,
      signedPage: null,
      placementsByPage: {},
      placementImageByPage: {},
      selectedPlacementIndex: null,
    );
  }

  void jumpTo(int page) {
    if (!state.loaded) return;
    final clamped = page.clamp(1, state.pageCount);
    state = state.copyWith(currentPage: clamped, selectedPlacementIndex: null);
  }

  // Set or clear the page that will receive the signature overlay.
  void setSignedPage(int? page) {
    if (!state.loaded) return;
    if (page == null) {
      state = state.copyWith(signedPage: null, selectedPlacementIndex: null);
    } else {
      final clamped = page.clamp(1, state.pageCount);
      state = state.copyWith(signedPage: clamped, selectedPlacementIndex: null);
    }
  }

  void setPageCount(int count) {
    if (!state.loaded) return;
    state = state.copyWith(pageCount: count.clamp(1, 9999));
  }

  // Multiple-signature helpers
  void addPlacement({
    required int page,
    required Rect rect,
    String image = 'default.png',
  }) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<Rect>>.from(state.placementsByPage);
    final list = List<Rect>.from(map[p] ?? const []);
    list.add(rect);
    map[p] = list;
    // Sync image mapping list
    final imgMap = Map<int, List<String>>.from(state.placementImageByPage);
    final imgList = List<String>.from(imgMap[p] ?? const []);
    imgList.add(image);
    imgMap[p] = imgList;
    state = state.copyWith(
      placementsByPage: map,
      placementImageByPage: imgMap,
      selectedPlacementIndex: null,
    );
  }

  void removePlacement({required int page, required int index}) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final map = Map<int, List<Rect>>.from(state.placementsByPage);
    final list = List<Rect>.from(map[p] ?? const []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      // Sync image mapping
      final imgMap = Map<int, List<String>>.from(state.placementImageByPage);
      final imgList = List<String>.from(imgMap[p] ?? const []);
      if (index >= 0 && index < imgList.length) {
        imgList.removeAt(index);
      }
      if (list.isEmpty) {
        map.remove(p);
        imgMap.remove(p);
      } else {
        map[p] = list;
        imgMap[p] = imgList;
      }
      state = state.copyWith(
        placementsByPage: map,
        placementImageByPage: imgMap,
        selectedPlacementIndex: null,
      );
    }
  }

  List<Rect> placementsOn(int page) {
    return List<Rect>.from(state.placementsByPage[page] ?? const []);
  }

  void selectPlacement(int? index) {
    if (!state.loaded) return;
    // Only allow valid index on current page; otherwise clear
    if (index == null) {
      state = state.copyWith(selectedPlacementIndex: null);
      return;
    }
    final list = state.placementsByPage[state.currentPage] ?? const [];
    if (index >= 0 && index < list.length) {
      state = state.copyWith(selectedPlacementIndex: index);
    } else {
      state = state.copyWith(selectedPlacementIndex: null);
    }
  }

  void deleteSelectedPlacement() {
    final idx = state.selectedPlacementIndex;
    if (idx == null) return;
    removePlacement(page: state.currentPage, index: idx);
  }

  // Assign a different image name to a placement on a page.
  void assignImageToPlacement({
    required int page,
    required int index,
    required String image,
  }) {
    if (!state.loaded) return;
    final p = page.clamp(1, state.pageCount);
    final imgMap = Map<int, List<String>>.from(state.placementImageByPage);
    final list = List<String>.from(imgMap[p] ?? const []);
    if (index >= 0 && index < list.length) {
      list[index] = image;
      imgMap[p] = list;
      state = state.copyWith(placementImageByPage: imgMap);
    }
  }

  // Convenience to get image name for a placement
  String? imageOfPlacement({required int page, required int index}) {
    final list = state.placementImageByPage[page] ?? const [];
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }
}

final pdfProvider = StateNotifierProvider<PdfController, PdfState>(
  (ref) => PdfController(),
);

class SignatureController extends StateNotifier<SignatureState> {
  SignatureController() : super(SignatureState.initial());
  static const Size pageSize = Size(400, 560);

  void resetForNewPage() {
    state = SignatureState.initial();
  }

  void placeDefaultRect() {
    final w = 120.0, h = 60.0;
    state = state.copyWith(
      rect: Rect.fromCenter(
        center: Offset(pageSize.width / 2, pageSize.height * 0.75),
        width: w,
        height: h,
      ),
      editingEnabled: true,
    );
  }

  void loadSample() {
    final w = 120.0, h = 60.0;
    state = state.copyWith(
      rect: Rect.fromCenter(
        center: Offset(pageSize.width / 2, pageSize.height * 0.75),
        width: w,
        height: h,
      ),
      editingEnabled: true,
    );
  }

  void setInvalidSelected(BuildContext context) {
    // Fallback message without localization to keep core logic testable
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid or unsupported file')),
    );
  }

  void drag(Offset delta) {
    if (state.rect == null || !state.editingEnabled) return;
    final moved = state.rect!.shift(delta);
    state = state.copyWith(rect: _clampRectToPage(moved));
  }

  void resize(Offset delta) {
    if (state.rect == null || !state.editingEnabled) return;
    final r = state.rect!;
    double newW = r.width + delta.dx;
    double newH = r.height + delta.dy;
    if (state.aspectLocked) {
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
      state = state.copyWith(rect: resized);
      return;
    }
    // Unlocked aspect: clamp each dimension independently
    newW = newW.clamp(20.0, pageSize.width);
    newH = newH.clamp(20.0, pageSize.height);
    Rect resized = Rect.fromLTWH(r.left, r.top, newW, newH);
    resized = _clampRectToPage(resized);
    state = state.copyWith(rect: resized);
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

  void toggleAspect(bool v) => state = state.copyWith(aspectLocked: v);
  void setBgRemoval(bool v) => state = state.copyWith(bgRemoval: v);
  void setContrast(double v) => state = state.copyWith(contrast: v);
  void setBrightness(double v) => state = state.copyWith(brightness: v);
  void setRotation(double deg) => state = state.copyWith(rotation: deg);

  void setStrokes(List<List<Offset>> strokes) =>
      state = state.copyWith(strokes: strokes);
  void ensureRectForStrokes() {
    state = state.copyWith(
      rect:
          state.rect ??
          Rect.fromCenter(
            center: Offset(pageSize.width / 2, pageSize.height * 0.75),
            width: 140,
            height: 70,
          ),
      editingEnabled: true,
    );
  }

  void setImageBytes(Uint8List bytes) {
    state = state.copyWith(imageBytes: bytes);
    if (state.rect == null) {
      placeDefaultRect();
    }
    // Mark as draft/editable when user just loaded image
    state = state.copyWith(editingEnabled: true);
  }

  void clearImage() {
    state = state.copyWith(imageBytes: null, rect: null, editingEnabled: false);
  }

  void placeAtCenter(Offset center, {double width = 120, double height = 60}) {
    Rect r = Rect.fromCenter(center: center, width: width, height: height);
    r = _clampRectToPage(r);
    state = state.copyWith(rect: r, editingEnabled: true);
  }

  // Confirm current signature: freeze editing and place it on the PDF as an immutable overlay.
  // Returns the Rect placed, or null if no rect to confirm.
  Rect? confirmCurrentSignature(WidgetRef ref) {
    final r = state.rect;
    if (r == null) return null;
    // Place onto the current page
    final pdf = ref.read(pdfProvider);
    if (!pdf.loaded) return null;
    ref.read(pdfProvider.notifier).addPlacement(page: pdf.currentPage, rect: r);
    // Freeze editing: keep rect for preview but disable interaction
    state = state.copyWith(editingEnabled: false);
    return r;
  }

  // Remove the active overlay (draft or confirmed preview) but keep image settings intact
  void clearActiveOverlay() {
    state = state.copyWith(rect: null, editingEnabled: false);
  }
}

final signatureProvider =
    StateNotifierProvider<SignatureController, SignatureState>(
      (ref) => SignatureController(),
    );

/// Derived provider that returns processed signature image bytes according to
/// current adjustment settings (contrast/brightness) and background removal.
/// Returns null if no image is loaded. The output is a PNG to preserve alpha.
final processedSignatureImageProvider = Provider<Uint8List?>((ref) {
  final s = ref.watch(signatureProvider);
  final bytes = s.imageBytes;
  if (bytes == null || bytes.isEmpty) return null;

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
  final double contrast = s.contrast; // [0..2], 1 = neutral
  final double brightness = s.brightness; // [-1..1], 0 = neutral
  final double rotationDeg = s.rotation; // degrees
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
      if (s.bgRemoval) {
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

  // Apply rotation if any (around center) using bilinear interpolation and keep size
  if (rotationDeg % 360 != 0) {
    // The image package rotates counter-clockwise; positive degrees rotate CCW
    out = img.copyRotate(
      out,
      angle: rotationDeg,
      interpolation: img.Interpolation.linear,
    );
  }

  // Encode as PNG to preserve transparency
  final png = img.encodePng(out, level: 6);
  return Uint8List.fromList(png);
});
