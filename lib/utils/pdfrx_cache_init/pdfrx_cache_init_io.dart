import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Initialize Pdfrx cache directory for IO platforms (mobile/desktop). No-op on web.
Future<void> initPdfrxCache() async {
  try {
    if (kIsWeb) return; // Guard (should not be used on web, but extra safety)
    if (Pdfrx.getCacheDirectory != null) return; // Already set
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/pdfrx_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    Pdfrx.getCacheDirectory = () async => cacheDir.path;
    debugPrint(
      '[pdfrx_cache_init_io] Pdfrx cache directory set to ${cacheDir.path}',
    );
  } catch (e, st) {
    debugPrint(
      '[pdfrx_cache_init_io] Failed to initialize Pdfrx cache directory: $e',
    );
    debugPrint(st.toString());
  }
}
