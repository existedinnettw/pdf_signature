import 'package:flutter/foundation.dart';

// On modern Flutter Web (Wasm GC, e.g., Chromium), dart:html is not available.
// Use js_interop capability to select the web implementation that relies on
// package:web instead of dart:html.
import 'download_stub.dart'
    if (dart.library.js_interop) 'download_web.dart'
    as impl;

/// Initiates a platform-appropriate download/save operation.
///
/// On Web: triggers a browser download with the provided filename.
/// On non-Web: returns false (no-op). Use your existing IO save flow instead.
Future<bool> downloadBytes(Uint8List bytes, {required String filename}) {
  debugPrint('downloadBytes: initiating download');
  return impl.downloadBytes(bytes, filename: filename);
}
