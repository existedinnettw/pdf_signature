import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_signature/app.dart';
import 'package:pdf_signature/utils/pdfrx_cache_init/pdfrx_cache_init.dart';
export 'package:pdf_signature/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize pdfrx core (safe to call multiple times) and set up cache directory.
  pdfrxFlutterInitialize();
  await initPdfrxCache();
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
