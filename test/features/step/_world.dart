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
  static int? pendingGoTo; // for simulating typed Go To value across steps

  // Preferences & settings
  static Map<String, String> prefs = {};
  static String systemTheme = 'light'; // simulated OS theme: 'light' | 'dark'
  static String deviceLocale = 'en'; // simulated device locale
  static String? selectedTheme; // 'light' | 'dark' | 'system'
  static String? currentTheme; // actual UI theme applied: 'light' | 'dark'
  static String? currentLanguage; // 'en' | 'zh-TW' | 'es'
  static bool settingsOpen = false;

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
    pendingGoTo = null;

    // Preferences
    prefs = {};
    systemTheme = 'light';
    deviceLocale = 'en';
    selectedTheme = null;
    currentTheme = null;
    currentLanguage = null;
    settingsOpen = false;
  }
}
