import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether to use a mock continuous viewer (ListView) instead of a real PDF viewer.
/// Tests will override this to true.
final useMockViewerProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false),
);

/// Global visibility toggle for signature overlays (placed items). Kept simple for tests.
final signatureVisibilityProvider = StateProvider<bool>((ref) => true);

/// Whether resizing keeps the current aspect ratio for the active overlay
final aspectLockedProvider = StateProvider<bool>((ref) => false);

/// Current active overlay rect (normalized 0..1) for the mock viewer.
/// Integration tests can read this to confirm or compute placements.
final activeRectProvider = StateProvider<Rect?>((ref) => null);
