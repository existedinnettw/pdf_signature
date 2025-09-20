import 'dart:typed_data';

import 'download_stub.dart' if (dart.library.html) 'download_web.dart' as impl;

/// Initiates a platform-appropriate download/save operation.
///
/// On Web: triggers a browser download with the provided filename.
/// On non-Web: returns false (no-op). Use your existing IO save flow instead.
Future<bool> downloadBytes(Uint8List bytes, {required String filename}) {
  return impl.downloadBytes(bytes, filename: filename);
}
