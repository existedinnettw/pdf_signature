import 'dart:typed_data';
import 'signature_asset.dart';
import 'graphic_adjust.dart';

/**
 * signature card is template of signature placement
 * Use the [SignatureCardRepository] to obtain a full [SignatureCard]
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

  factory SignatureCard.initial() => SignatureCard(
    rotationDeg: 0.0,
    asset: SignatureAsset(id: '', bytes: Uint8List(0)),
    graphicAdjust: const GraphicAdjust(),
  );
}
