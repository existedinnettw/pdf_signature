import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

/// Web stub: pdfrx can operate without a filesystem cache; leave getCacheDirectory null.
Future<void> initPdfrxCache() async {
  // Intentionally no-op. If desired, could set an in-memory indicator.
  debugPrint(
    '[pdfrx_cache_init_web] Skipping Pdfrx cache directory setup on web',
  );
  // Ensure any previous (hot-reload) IO assignment isn't kept when switching target.
  if (kIsWeb && Pdfrx.getCacheDirectory != null) {
    // Leave as-is; clearing could break existing references. Merely log.
    debugPrint(
      '[pdfrx_cache_init_web] Existing getCacheDirectory left unchanged',
    );
  }
}
