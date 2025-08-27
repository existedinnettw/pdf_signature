part of 'viewer.dart';

class PdfState {
  final bool loaded;
  final int pageCount;
  final int currentPage;
  final bool markedForSigning;
  final String? pickedPdfPath;
  const PdfState({
    required this.loaded,
    required this.pageCount,
    required this.currentPage,
    required this.markedForSigning,
    this.pickedPdfPath,
  });
  factory PdfState.initial() => const PdfState(
    loaded: false,
    pageCount: 0,
    currentPage: 1,
    markedForSigning: false,
  );
  PdfState copyWith({
    bool? loaded,
    int? pageCount,
    int? currentPage,
    bool? markedForSigning,
    String? pickedPdfPath,
  }) => PdfState(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    currentPage: currentPage ?? this.currentPage,
    markedForSigning: markedForSigning ?? this.markedForSigning,
    pickedPdfPath: pickedPdfPath ?? this.pickedPdfPath,
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
    );
  }

  void openPicked({required String path, int pageCount = samplePageCount}) {
    state = state.copyWith(
      loaded: true,
      pageCount: pageCount,
      currentPage: 1,
      markedForSigning: false,
      pickedPdfPath: path,
    );
  }

  void jumpTo(int page) {
    if (!state.loaded) return;
    final clamped = page.clamp(1, state.pageCount);
    state = state.copyWith(currentPage: clamped);
  }

  void toggleMark() {
    if (!state.loaded) return;
    state = state.copyWith(markedForSigning: !state.markedForSigning);
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
    double newW = (r.width + delta.dx).clamp(20, pageSize.width);
    double newH = (r.height + delta.dy).clamp(20, pageSize.height);
    if (state.aspectLocked) {
      final aspect = r.width / r.height;
      if ((delta.dx / r.width).abs() >= (delta.dy / r.height).abs()) {
        newH = newW / aspect;
      } else {
        newW = newH * aspect;
      }
    }
    Rect resized = Rect.fromLTWH(r.left, r.top, newW, newH);
    resized = _clampRectToPage(resized);
    state = state.copyWith(rect: resized);
  }

  Rect _clampRectToPage(Rect r) {
    double left = r.left.clamp(0.0, pageSize.width - r.width);
    double top = r.top.clamp(0.0, pageSize.height - r.height);
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
