import 'dart:typed_data';

import 'package:flutter/widgets.dart';

Future<bool> downloadBytes(Uint8List bytes, {required String filename}) async {
  // Not supported on non-web. Return false so caller can fallback to file save.
  debugPrint('downloadBytes: not supported on this platform');
  return false;
}
