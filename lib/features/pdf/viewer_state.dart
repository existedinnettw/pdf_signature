part of 'viewer.dart';

class PdfState {
  final bool loaded;
  final int pageCount;
  final int currentPage;
  final bool markedForSigning;
  final String? pickedPdfPath;
  final int? signedPage;
  const PdfState({
    required this.loaded,
    required this.pageCount,
    required this.currentPage,
    required this.markedForSigning,
    this.pickedPdfPath,
    this.signedPage,
  });
  factory PdfState.initial() => const PdfState(
    loaded: false,
    pageCount: 0,
    currentPage: 1,
    markedForSigning: false,
    signedPage: null,
  );
  PdfState copyWith({
    bool? loaded,
    int? pageCount,
    int? currentPage,
    bool? markedForSigning,
    String? pickedPdfPath,
    int? signedPage,
  }) => PdfState(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    currentPage: currentPage ?? this.currentPage,
    markedForSigning: markedForSigning ?? this.markedForSigning,
    pickedPdfPath: pickedPdfPath ?? this.pickedPdfPath,
    signedPage: signedPage ?? this.signedPage,
  );
}

class PdfController extends StateNotifier<PdfState> {
  PdfController() : super(PdfState.initial());
  static const int samplePageCount = 5;
  void openSample() {
    state = state.copyWith(
      loaded: true,
      pageCount: samplePageCount,
      currentPage: 1,
      markedForSigning: false,
      pickedPdfPath: null,
      signedPage: null,
    );
  }

  void openPicked({required String path, int pageCount = samplePageCount}) {
    state = state.copyWith(
      loaded: true,
      pageCount: pageCount,
      currentPage: 1,
      markedForSigning: false,
      pickedPdfPath: path,
      signedPage: null,
    );
  }

  void jumpTo(int page) {
    if (!state.loaded) return;
    final clamped = page.clamp(1, state.pageCount);
    state = state.copyWith(currentPage: clamped);
  }

  void toggleMark() {
    if (!state.loaded) return;
    if (state.signedPage != null) {
      state = state.copyWith(markedForSigning: false, signedPage: null);
    } else {
      state = state.copyWith(
        markedForSigning: true,
        signedPage: state.currentPage,
      );
    }
  }

  void setPageCount(int count) {
    if (!state.loaded) return;
    state = state.copyWith(pageCount: count.clamp(1, 9999));
  }
}

final pdfProvider = StateNotifierProvider<PdfController, PdfState>(
  (ref) => PdfController(),
);

class SignatureState {
  final Rect? rect;
  final bool aspectLocked;
  final bool bgRemoval;
  final double contrast;
  final double brightness;
  final List<List<Offset>> strokes;
  final Uint8List? imageBytes;
  const SignatureState({
    required this.rect,
    required this.aspectLocked,
    required this.bgRemoval,
    required this.contrast,
    required this.brightness,
    required this.strokes,
    this.imageBytes,
  });
  factory SignatureState.initial() => const SignatureState(
    rect: null,
    aspectLocked: false,
    bgRemoval: false,
    contrast: 1.0,
    brightness: 0.0,
    strokes: const [],
    imageBytes: null,
  );
  SignatureState copyWith({
    Rect? rect,
    bool? aspectLocked,
    bool? bgRemoval,
    double? contrast,
    double? brightness,
    List<List<Offset>>? strokes,
    Uint8List? imageBytes,
  }) => SignatureState(
    rect: rect ?? this.rect,
    aspectLocked: aspectLocked ?? this.aspectLocked,
    bgRemoval: bgRemoval ?? this.bgRemoval,
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    strokes: strokes ?? this.strokes,
    imageBytes: imageBytes ?? this.imageBytes,
  );
}

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
    );
  }

  void setInvalidSelected(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid or unsupported file')),
    );
  }

  void drag(Offset delta) {
    if (state.rect == null) return;
    final moved = state.rect!.shift(delta);
    state = state.copyWith(rect: _clampRectToPage(moved));
  }

  void resize(Offset delta) {
    if (state.rect == null) return;
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
    );
  }

  void setImageBytes(Uint8List bytes) {
    state = state.copyWith(imageBytes: bytes);
    if (state.rect == null) {
      placeDefaultRect();
    }
  }
}

final signatureProvider =
    StateNotifierProvider<SignatureController, SignatureState>(
      (ref) => SignatureController(),
    );
