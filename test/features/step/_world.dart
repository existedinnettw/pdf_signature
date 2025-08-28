import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tiny shared world for BDD steps to share state within a scenario.
class TestWorld {
  static ProviderContainer? container;

  // Signature helpers
  static Offset? prevCenter;
  static double? prevAspect;
  static double? prevContrast;
  static double? prevBrightness;

  // Export/save helpers
  static Uint8List? lastExportBytes;
  static String? lastSavedPath;
  static bool exportInProgress = false;
  static bool nothingToSaveAttempt = false;

  // Generic flags/values
  static int? selectedPage;

  static void reset() {
    prevCenter = null;
    prevAspect = null;
    prevContrast = null;
    prevBrightness = null;
    lastExportBytes = null;
    lastSavedPath = null;
    exportInProgress = false;
    nothingToSaveAttempt = false;
    selectedPage = null;
  }
}
