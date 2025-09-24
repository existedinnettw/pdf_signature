// Implementation for Web using package:web to support Wasm GC (Chromium)
// without importing dart:html directly.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<bool> downloadBytes(Uint8List bytes, {required String filename}) async {
  try {
    // Use a data URL to avoid Blob/typed array interop issues under Wasm GC.
    final url = 'data:application/pdf;base64,${base64Encode(bytes)}';

    // Create an anchor element and trigger a click to download
    final anchor =
        web.HTMLAnchorElement()
          ..href = url
          ..download = filename
          ..style.display = 'none';

    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    return true;
  } catch (e, st) {
    debugPrint('Error: downloadBytes failed: $e\n$st');
    return false;
  }
}
