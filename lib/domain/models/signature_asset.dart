import 'dart:typed_data';

/// SignatureAsset store image file of a signature, stored in the device or cloud storage
class SignatureAsset {
  final Uint8List bytes;
  // List<List<Offset>>? strokes;
  final String? name; // optional display name (e.g., filename)
  const SignatureAsset({required this.bytes, this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureAsset &&
          name == other.name &&
          _bytesEqual(bytes, other.bytes);

  @override
  int get hashCode => name.hashCode ^ bytes.length.hashCode;

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
