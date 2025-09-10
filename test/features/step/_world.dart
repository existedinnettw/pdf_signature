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
  // Signature image name loaded via steps (e.g., 'alice.png')
  static String? currentImageName;
  // Counters for steps that are called multiple times without params
  static int placeFromPictureCallCount = 0;

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
    currentImageName = null;
    placeFromPictureCallCount = 0;
  }
}

// Mock signature state for tests
class MockSignatureState {
  List<List<Offset>> strokes = [];
  Uint8List? imageBytes;
  bool bgRemoval = false;
  Rect? rect;
  double contrast = 1.0;
  double brightness = 0.0;

  MockSignatureState({
    List<List<Offset>>? strokes,
    this.imageBytes,
    this.bgRemoval = false,
    this.rect,
    this.contrast = 1.0,
    this.brightness = 0.0,
  }) : strokes = strokes ?? [];
}

class MockSignatureNotifier extends StateNotifier<MockSignatureState> {
  MockSignatureNotifier() : super(MockSignatureState());

  void setStrokes(List<List<Offset>> strokes) {
    state = MockSignatureState(
      strokes: List.from(strokes),
      imageBytes: state.imageBytes,
      bgRemoval: state.bgRemoval,
      rect: state.rect,
      contrast: state.contrast,
      brightness: state.brightness,
    );
  }

  void setImageBytes(Uint8List bytes) {
    state = MockSignatureState(
      strokes: List.from(state.strokes),
      imageBytes: bytes,
      bgRemoval: state.bgRemoval,
      rect: state.rect,
      contrast: state.contrast,
      brightness: state.brightness,
    );
    // Mock processing: just set the processed image to the same bytes
    TestWorld.container?.read(processedSignatureImageProvider.notifier).state =
        bytes;
  }

  void setBgRemoval(bool value) {
    state = MockSignatureState(
      strokes: List.from(state.strokes),
      imageBytes: state.imageBytes,
      bgRemoval: value,
      rect: state.rect,
      contrast: state.contrast,
      brightness: state.brightness,
    );
  }

  void clearImage() {
    state = MockSignatureState(
      strokes: List.from(state.strokes),
      imageBytes: null,
      bgRemoval: state.bgRemoval,
      rect: state.rect,
      contrast: state.contrast,
      brightness: state.brightness,
    );
  }

  void setContrast(double value) {
    state = MockSignatureState(
      strokes: List.from(state.strokes),
      imageBytes: state.imageBytes,
      bgRemoval: state.bgRemoval,
      rect: state.rect,
      contrast: value,
      brightness: state.brightness,
    );
  }

  void setBrightness(double value) {
    state = MockSignatureState(
      strokes: List.from(state.strokes),
      imageBytes: state.imageBytes,
      bgRemoval: state.bgRemoval,
      rect: state.rect,
      contrast: state.contrast,
      brightness: value,
    );
  }
}

final signatureProvider =
    StateNotifierProvider<MockSignatureNotifier, MockSignatureState>(
      (ref) => MockSignatureNotifier(),
    );

// Mock other providers
final currentRectProvider = StateProvider<Rect?>((ref) => null);
final editingEnabledProvider = StateProvider<bool>((ref) => false);
final aspectLockedProvider = StateProvider<bool>((ref) => false);
final processedSignatureImageProvider = StateProvider<Uint8List?>(
  (ref) => null,
);
