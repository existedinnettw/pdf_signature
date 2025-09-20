import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;

part 'signature_asset.freezed.dart';

/// SignatureAsset store image file of a signature, stored in the device or cloud storage
@freezed
abstract class SignatureAsset with _$SignatureAsset {
  const SignatureAsset._();

  const factory SignatureAsset({required img.Image sigImage, String? name}) =
      _SignatureAsset;

  /// Encode this image to PNG bytes. Use a small compression level for speed by default.
  Uint8List toPngBytes({int level = 3}) =>
      Uint8List.fromList(img.encodePng(sigImage, level: level));
}
