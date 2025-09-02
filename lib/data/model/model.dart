import 'dart:typed_data';
import 'package:flutter/widgets.dart';

class PdfState {
  final bool loaded;
  final int pageCount;
  final int currentPage;
  final String? pickedPdfPath;
  final Uint8List? pickedPdfBytes;
  final int? signedPage;
  // Multiple signature placements per page, stored as UI-space rects (e.g., 400x560)
  final Map<int, List<Rect>> placementsByPage;
  // For each placement, store the assigned image identifier (e.g., filename) in the same index order.
  final Map<int, List<String>> placementImageByPage;
  // UI state: selected placement index on the current page (if any)
  final int? selectedPlacementIndex;
  const PdfState({
    required this.loaded,
    required this.pageCount,
    required this.currentPage,
    this.pickedPdfPath,
    this.pickedPdfBytes,
    this.signedPage,
    this.placementsByPage = const {},
    this.placementImageByPage = const {},
    this.selectedPlacementIndex,
  });
  factory PdfState.initial() => const PdfState(
    loaded: false,
    pageCount: 0,
    currentPage: 1,
    pickedPdfBytes: null,
    signedPage: null,
    placementsByPage: {},
    placementImageByPage: {},
    selectedPlacementIndex: null,
  );
  PdfState copyWith({
    bool? loaded,
    int? pageCount,
    int? currentPage,
    String? pickedPdfPath,
    Uint8List? pickedPdfBytes,
    int? signedPage,
    Map<int, List<Rect>>? placementsByPage,
    Map<int, List<String>>? placementImageByPage,
    int? selectedPlacementIndex,
  }) => PdfState(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    currentPage: currentPage ?? this.currentPage,
    pickedPdfPath: pickedPdfPath ?? this.pickedPdfPath,
    pickedPdfBytes: pickedPdfBytes ?? this.pickedPdfBytes,
    signedPage: signedPage ?? this.signedPage,
    placementsByPage: placementsByPage ?? this.placementsByPage,
    placementImageByPage: placementImageByPage ?? this.placementImageByPage,
    selectedPlacementIndex:
        selectedPlacementIndex ?? this.selectedPlacementIndex,
  );
}

class SignatureState {
  final Rect? rect;
  final bool aspectLocked;
  final bool bgRemoval;
  final double contrast;
  final double brightness;
  // Rotation in degrees applied to the signature image when rendering/exporting
  final double rotation;
  final List<List<Offset>> strokes;
  final Uint8List? imageBytes;
  // When true, the active signature overlay is movable/resizable and should not be exported.
  // When false, the overlay is confirmed (unmovable) and eligible for export.
  final bool editingEnabled;
  const SignatureState({
    required this.rect,
    required this.aspectLocked,
    required this.bgRemoval,
    required this.contrast,
    required this.brightness,
    this.rotation = 0.0,
    required this.strokes,
    this.imageBytes,
    this.editingEnabled = false,
  });
  factory SignatureState.initial() => const SignatureState(
    rect: null,
    aspectLocked: false,
    bgRemoval: false,
    contrast: 1.0,
    brightness: 0.0,
    rotation: 0.0,
    strokes: [],
    imageBytes: null,
    editingEnabled: false,
  );
  SignatureState copyWith({
    Rect? rect,
    bool? aspectLocked,
    bool? bgRemoval,
    double? contrast,
    double? brightness,
    double? rotation,
    List<List<Offset>>? strokes,
    Uint8List? imageBytes,
    bool? editingEnabled,
  }) => SignatureState(
    rect: rect ?? this.rect,
    aspectLocked: aspectLocked ?? this.aspectLocked,
    bgRemoval: bgRemoval ?? this.bgRemoval,
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    rotation: rotation ?? this.rotation,
    strokes: strokes ?? this.strokes,
    imageBytes: imageBytes ?? this.imageBytes,
    editingEnabled: editingEnabled ?? this.editingEnabled,
  );
}
