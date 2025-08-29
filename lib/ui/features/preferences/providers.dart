import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple supported locales
const supportedLocales = <Locale>[
  Locale('en'),
  Locale('zh', 'TW'),
  Locale('es'),
];

// Keys
const _kTheme = 'theme'; // 'light'|'dark'|'system'
const _kLanguage = 'language'; // 'en'|'zh-TW'|'es'

String _normalizeLanguageTag(String tag) {
  final parts = tag.split('-');
  if (parts.isEmpty) return 'en';
  final primary = parts[0].toLowerCase();
  if (primary == 'en') return 'en';
  if (primary == 'es') return 'es';
  if (primary == 'zh') {
    final region = parts.length > 1 ? parts[1].toUpperCase() : '';
    if (region == 'TW') return 'zh-TW';
    // other zh regions not supported; fall back to English
    return 'en';
  }
  // Fallback default
  return 'en';
}

class PreferencesState {
  final String theme; // 'light' | 'dark' | 'system'
  final String language; // 'en' | 'zh-TW' | 'es'
  const PreferencesState({required this.theme, required this.language});

  PreferencesState copyWith({String? theme, String? language}) =>
      PreferencesState(
        theme: theme ?? this.theme,
        language: language ?? this.language,
      );
}

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final SharedPreferences prefs;
  PreferencesNotifier(this.prefs)
    : super(
        PreferencesState(
          theme: prefs.getString(_kTheme) ?? 'system',
          language: _normalizeLanguageTag(
            prefs.getString(_kLanguage) ??
                WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
          ),
        ),
      ) {
    // normalize language to supported/fallback
    _ensureValid();
  }

  void _ensureValid() {
    final themeValid = {'light', 'dark', 'system'};
    if (!themeValid.contains(state.theme)) {
      state = state.copyWith(theme: 'system');
      prefs.setString(_kTheme, 'system');
    }
    final normalized = _normalizeLanguageTag(state.language);
    if (normalized != state.language) {
      state = state.copyWith(language: normalized);
      prefs.setString(_kLanguage, normalized);
    }
  }

  Future<void> setTheme(String theme) async {
    final valid = {'light', 'dark', 'system'};
    if (!valid.contains(theme)) return;
    state = state.copyWith(theme: theme);
    await prefs.setString(_kTheme, theme);
  }

  Future<void> setLanguage(String language) async {
    final normalized = _normalizeLanguageTag(language);
    state = state.copyWith(language: normalized);
    await prefs.setString(_kLanguage, normalized);
  }

  Future<void> resetToDefaults() async {
  final device = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
  final normalized = _normalizeLanguageTag(device);
  state = PreferencesState(theme: 'system', language: normalized);
  await prefs.setString(_kTheme, 'system');
  await prefs.setString(_kLanguage, normalized);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  final p = await SharedPreferences.getInstance();
  return p;
});

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
      // In tests, you can override sharedPreferencesProvider
      final prefs = ref
          .watch(sharedPreferencesProvider)
          .maybeWhen(
            data: (p) => p,
            orElse: () => throw StateError('SharedPreferences not ready'),
          );
      return PreferencesNotifier(prefs);
    });

/// Derive the active ThemeMode based on preference and platform brightness
final themeModeProvider = Provider<ThemeMode>((ref) {
  final prefs = ref.watch(preferencesProvider);
  switch (prefs.theme) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
});

Locale _parseLanguageTag(String tag) {
  // 'zh-TW' -> ('zh','TW')
  final parts = tag.split('-');
  if (parts.length == 2) return Locale(parts[0], parts[1]);
  return Locale(parts[0]);
}

final localeProvider = Provider<Locale?>((ref) {
  final prefs = ref.watch(preferencesProvider);
  // Return explicit Locale for supported ones; if not supported, null to follow device
  final supported = {'en', 'zh-TW', 'es'};
  if (supported.contains(prefs.language)) {
    return _parseLanguageTag(prefs.language);
  }
  return null;
});
