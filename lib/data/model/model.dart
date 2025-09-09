import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// A simple library of signature images available to the user in the sidebar.
class SignatureAsset {
  final String id; // unique id
  final Uint8List bytes;
  // List<List<Offset>>? strokes;
  final String? name; // optional display name (e.g., filename)
  const SignatureAsset({required this.id, required this.bytes, this.name});
}

class GraphicAdjust {
  final double contrast;
  final double brightness;
  final bool bgRemoval;

  const GraphicAdjust({
    this.contrast = 1.0,
    this.brightness = 0.0,
    this.bgRemoval = false,
  });

  GraphicAdjust copyWith({
    double? contrast,
    double? brightness,
    bool? bgRemoval,
  }) => GraphicAdjust(
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    bgRemoval: bgRemoval ?? this.bgRemoval,
  );
}

/**
 * signature card is template of signature placement
 */
class SignatureCard {
  final double rotationDeg;
  final SignatureAsset asset;
  final GraphicAdjust graphicAdjust;

  const SignatureCard({
    required this.rotationDeg,
    required this.asset,
    this.graphicAdjust = const GraphicAdjust(),
  });

  SignatureCard copyWith({
    double? rotationDeg,
    SignatureAsset? asset,
    GraphicAdjust? graphicAdjust,
  }) => SignatureCard(
    rotationDeg: rotationDeg ?? this.rotationDeg,
    asset: asset ?? this.asset,
    graphicAdjust: graphicAdjust ?? this.graphicAdjust,
  );
}

/// Represents a single signature placement on a page combining both the
/// geometric rectangle (UI coordinate space) and the signature asset
/// assigned to that placement.
class SignaturePlacement {
  // The bounding box of this placement in UI coordinate space, implies scaling and position.
  final Rect rect;

  /// Rotation in degrees to apply when rendering/exporting this placement.
  final double rotationDeg;
  final GraphicAdjust graphicAdjust;
  final SignatureAsset asset;

  const SignaturePlacement({
    required this.rect,
    required this.asset,
    this.rotationDeg = 0.0,
    this.graphicAdjust = const GraphicAdjust(),
  });

  SignaturePlacement copyWith({
    Rect? rect,
    SignatureAsset? asset,
    double? rotationDeg,
    GraphicAdjust? graphicAdjust,
  }) => SignaturePlacement(
    rect: rect ?? this.rect,
    asset: asset ?? this.asset,
    rotationDeg: rotationDeg ?? this.rotationDeg,
    graphicAdjust: graphicAdjust ?? this.graphicAdjust,
  );
}

class PdfState {
  final bool loaded;
  final int pageCount;
  final int currentPage;
  final String? pickedPdfPath;
  final Uint8List? pickedPdfBytes;
  final int? signedPage;
  // Multiple signature placements per page, each combines geometry and asset.
  final Map<int, List<SignaturePlacement>> placementsByPage;
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
    this.selectedPlacementIndex,
  });
  factory PdfState.initial() => const PdfState(
    loaded: false,
    pageCount: 0,
    currentPage: 1,
    pickedPdfBytes: null,
    signedPage: null,
    placementsByPage: {},
    selectedPlacementIndex: null,
  );
  PdfState copyWith({
    bool? loaded,
    int? pageCount,
    int? currentPage,
    String? pickedPdfPath,
    Uint8List? pickedPdfBytes,
    int? signedPage,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    int? selectedPlacementIndex,
  }) => PdfState(
    loaded: loaded ?? this.loaded,
    pageCount: pageCount ?? this.pageCount,
    currentPage: currentPage ?? this.currentPage,
    pickedPdfPath: pickedPdfPath ?? this.pickedPdfPath,
    pickedPdfBytes: pickedPdfBytes ?? this.pickedPdfBytes,
    signedPage: signedPage ?? this.signedPage,
    placementsByPage: placementsByPage ?? this.placementsByPage,
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
  // The signature asset the current overlay is based on (from library)
  final SignatureAsset? asset;
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
    this.asset,
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
    asset: null,
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
    SignatureAsset? asset,
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
    asset: asset ?? this.asset,
    editingEnabled: editingEnabled ?? this.editingEnabled,
  );
}
