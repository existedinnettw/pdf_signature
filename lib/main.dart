import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_signature/app.dart';
export 'package:pdf_signature/app.dart';

Future<void> _initPdfrxCache() async {
  try {
    // Only set once; guard for hot reload/tests
    if (Pdfrx.getCacheDirectory == null) {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/pdfrx_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      Pdfrx.getCacheDirectory = () async => cacheDir.path;
      debugPrint('[main] Pdfrx cache directory set to ${cacheDir.path}');
    }
  } catch (e, st) {
    debugPrint('[main] Failed to initialize Pdfrx cache directory: $e');
    debugPrint(st.toString());
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initPdfrxCache();
  // Disable right-click context menu on web using Flutter API
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      // Empty implementation in release mode, effectively disabling debugPrint
    };
  }
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
  runApp(const MyApp());
}
