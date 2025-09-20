import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'graphic_adjust.dart';
import 'signature_asset.dart';

part 'signature_placement.freezed.dart';

/// Represents a single signature placement on a page combining both the
/// geometric rectangle (UI coordinate space) and the signature asset
/// assigned to that placement.
@freezed
abstract class SignaturePlacement with _$SignaturePlacement {
  const factory SignaturePlacement({
    required Rect rect,
    required SignatureAsset asset,
    @Default(0.0) double rotationDeg,
    @Default(GraphicAdjust()) GraphicAdjust graphicAdjust,
  }) = _SignaturePlacement;
}
