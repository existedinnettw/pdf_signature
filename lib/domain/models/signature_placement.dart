import 'dart:ui';
import 'signature_asset.dart';
import 'graphic_adjust.dart';

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
