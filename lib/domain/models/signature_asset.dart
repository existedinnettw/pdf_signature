import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// SignatureAsset store image file of a signature, stored in the device or cloud storage
class SignatureAsset {
  final img.Image sigImage;
  // List<List<Offset>>? strokes;
  final String? name; // optional display name (e.g., filename)
  const SignatureAsset({required this.sigImage, this.name});

  /// Encode this image to PNG bytes. Use a small compression level for speed by default.
  Uint8List toPngBytes({int level = 3}) =>
      Uint8List.fromList(img.encodePng(sigImage, level: level));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureAsset &&
          name == other.name &&
          sigImage == other.sigImage;

  @override
  int get hashCode =>
      name.hashCode ^ sigImage.width.hashCode ^ sigImage.height.hashCode;
}
