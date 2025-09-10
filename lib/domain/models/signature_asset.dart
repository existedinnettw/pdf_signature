import 'dart:typed_data';

/// SignatureAsset store image file of a signature, stored in the device or cloud storage
class SignatureAsset {
  final Uint8List bytes;
  // List<List<Offset>>? strokes;
  final String? name; // optional display name (e.g., filename)
  const SignatureAsset({required this.bytes, this.name});
}
