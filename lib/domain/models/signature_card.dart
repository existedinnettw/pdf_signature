import 'signature_asset.dart';
import 'package:image/image.dart' as img;
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
    required this.asset,
    required this.rotationDeg,
    this.graphicAdjust = const GraphicAdjust(),
  });

  SignatureCard copyWith({
    double? rotationDeg, //z axis is out of the screen, positive is CCW
    SignatureAsset? asset,
    GraphicAdjust? graphicAdjust,
  }) => SignatureCard(
    rotationDeg: rotationDeg ?? this.rotationDeg,
    asset: asset ?? this.asset,
    graphicAdjust: graphicAdjust ?? this.graphicAdjust,
  );

  factory SignatureCard.initial() => SignatureCard(
    asset: SignatureAsset(sigImage: img.Image(width: 1, height: 1)),
    rotationDeg: 0.0,
    graphicAdjust: const GraphicAdjust(),
  );
}
