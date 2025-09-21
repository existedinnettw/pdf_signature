import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_signature/app.dart';
export 'package:pdf_signature/app.dart';

void main() {
  // Ensure Flutter bindings are initialized before platform channel usage
  WidgetsFlutterBinding.ensureInitialized();
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
