import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:pdf_signature/domain/models/preferences.dart';

// Helpers to work with BCP-47 language tags
String toLanguageTag(Locale loc) {
  final lang = loc.languageCode.toLowerCase();
  final region = loc.countryCode;
  if (region == null || region.isEmpty) return lang;
  return '$lang-${region.toUpperCase()}';
}

Locale _parseLanguageTag(String tag) {
  final cleaned = tag.replaceAll('_', '-');
  final parts = cleaned.split('-');
  if (parts.length >= 2 && parts[1].isNotEmpty) {
    return Locale(parts[0].toLowerCase(), parts[1].toUpperCase());
  }
  return Locale(parts[0].toLowerCase());
}

Set<String> _supportedTags() {
  return AppLocalizations.supportedLocales.map((l) => toLanguageTag(l)).toSet();
}

// Keys
const _kTheme = 'theme'; // 'light'|'dark'|'system'
const _kThemeColor = 'theme_color'; // 'blue'|'green'|'red'|'purple'
const _kLanguage = 'language'; // BCP-47 tag like 'en', 'zh-TW', 'es'
const _kPageView = 'page_view'; // now only 'continuous'
const _kExportDpi = 'export_dpi'; // double, allowed: 96,144,200,300

String _normalizeLanguageTag(String tag) {
  final tags = _supportedTags();
  if (tag.isEmpty) return tags.contains('en') ? 'en' : tags.first;
  // Replace underscore with hyphen and canonicalize case
  final normalized = () {
    final t = tag.replaceAll('_', '-');
    final parts = t.split('-');
    final lang = parts[0].toLowerCase();
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '$lang-${parts[1].toUpperCase()}';
    }
    return lang;
  }();

  // Exact match
  if (tags.contains(normalized)) return normalized;

  // Try fallback to language-only if available
  final langOnly = normalized.split('-')[0];
  if (tags.contains(langOnly)) return langOnly;

  // Try to pick first tag with same language
  final candidate = tags.firstWhere(
    (t) => t.split('-')[0] == langOnly,
    orElse: () => '',
  );
  if (candidate.isNotEmpty) return candidate;

  // Final fallback to English or first supported
  return tags.contains('en') ? 'en' : tags.first;
}

class PreferencesStateNotifier extends StateNotifier<PreferencesState> {
  final SharedPreferences prefs;
  PreferencesStateNotifier(this.prefs)
    : super(
        PreferencesState(
          theme: prefs.getString(_kTheme) ?? 'system',
          language: _normalizeLanguageTag(
            prefs.getString(_kLanguage) ??
                WidgetsBinding.instance.platformDispatcher.locale
                    .toLanguageTag(),
          ),
          exportDpi: _readDpi(prefs),
          theme_color: prefs.getString(_kThemeColor) ?? 'blue',
        ),
      ) {
    // normalize language to supported/fallback
    _ensureValid();
  }

  static double _readDpi(SharedPreferences prefs) {
    final d = prefs.getDouble(_kExportDpi);
    if (d == null) return 144.0;
    const allowed = [96.0, 144.0, 200.0, 300.0];
    return allowed.contains(d) ? d : 144.0;
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
    // Ensure DPI is one of allowed values
    const allowed = [96.0, 144.0, 200.0, 300.0];
    if (!allowed.contains(state.exportDpi)) {
      state = state.copyWith(exportDpi: 144.0);
      prefs.setDouble(_kExportDpi, 144.0);
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
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    final normalized = _normalizeLanguageTag(device);
    state = PreferencesState(
      theme: 'system',
      language: normalized,
      exportDpi: 144.0,
      theme_color: '',
    );
    await prefs.setString(_kTheme, 'system');
    await prefs.setString(_kLanguage, normalized);
    await prefs.setString(_kPageView, 'continuous');
    await prefs.setDouble(_kExportDpi, 144.0);
  }

  Future<void> setExportDpi(double dpi) async {
    const allowed = [96.0, 144.0, 200.0, 300.0];
    if (!allowed.contains(dpi)) return;
    state = state.copyWith(exportDpi: dpi);
    await prefs.setDouble(_kExportDpi, dpi);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  final p = await SharedPreferences.getInstance();
  return p;
});

final preferencesRepositoryProvider =
    StateNotifierProvider<PreferencesStateNotifier, PreferencesState>((ref) {
      // In tests, you can override sharedPreferencesProvider
      final prefs = ref
          .watch(sharedPreferencesProvider)
          .maybeWhen(
            data: (p) => p,
            orElse: () => throw StateError('SharedPreferences not ready'),
          );
      return PreferencesStateNotifier(prefs);
    });

// pageViewModeProvider removed; the app always runs in continuous mode.

/// Derive the active ThemeMode based on preference and platform brightness
final themeModeProvider = Provider<ThemeMode>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
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

final localeProvider = Provider<Locale?>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  final supported = _supportedTags();
  // Return explicit Locale for supported ones; if not supported, null to follow device
  if (supported.contains(prefs.language)) {
    return _parseLanguageTag(prefs.language);
  }
  return null;
});

/// Provides a map of BCP-47 tag -> autonym (self name), independent of UI locale.
final languageAutonymsProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final tags = _supportedTags().toList()..sort();
  final delegate = LocaleNamesLocalizationsDelegate();
  final Map<String, String> result = {};
  for (final tag in tags) {
    final locale = _parseLanguageTag(tag);
    final names = await delegate.load(locale);
    final name = names.nameOf(tag) ?? tag;
    result[tag] = name;
  }
  return result;
});
