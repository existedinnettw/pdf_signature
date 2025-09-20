import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;

import 'graphic_adjust.dart';
import 'signature_asset.dart';

part 'signature_card.freezed.dart';

/**
 * signature card is template of signature placement
 * Use the [SignatureCardRepository] to obtain a full [SignatureCard]
 */
@freezed
abstract class SignatureCard with _$SignatureCard {
  const factory SignatureCard({
    required SignatureAsset asset,
    @Default(0.0) double rotationDeg,
    @Default(GraphicAdjust()) GraphicAdjust graphicAdjust,
  }) = _SignatureCard;

  factory SignatureCard.initial() => SignatureCard(
    asset: SignatureAsset(sigImage: img.Image(width: 1, height: 1)),
  );
}
