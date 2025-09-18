import 'dart:typed_data';

Future<bool> downloadBytes(Uint8List bytes, {required String filename}) async {
  // Not supported on non-web. Return false so caller can fallback to file save.
  return false;
}
