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
// Theme color persisted as hex ARGB string (e.g., '#FF2196F3').
// Backward compatible with historical names like 'blue', 'indigo', etc.
const _kThemeColor = 'theme_color';
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
  static Color? _tryParseColor(String? s) {
    if (s == null || s.isEmpty) return null;
    final v = s.trim();
    // 1) Direct hex formats: #AARRGGBB, #RRGGBB, AARRGGBB, RRGGBB
    String hex = v.startsWith('#') ? v.substring(1) : v;
    // Accept 0xAARRGGBB / 0xRRGGBB as well
    if (hex.toLowerCase().startsWith('0x')) hex = hex.substring(2);
    if (hex.length == 6) {
      final intVal = int.tryParse('FF$hex', radix: 16);
      if (intVal != null) return Color(intVal);
    } else if (hex.length == 8) {
      final intVal = int.tryParse(hex, radix: 16);
      if (intVal != null) return Color(intVal);
    }

    // 2) Parse from Color(...) or MaterialColor(...) toString outputs
    //    e.g., 'Color(0xff2196f3)' or 'MaterialColor(primary value: Color(0xff2196f3))'
    final lower = v.toLowerCase();
    final idx = lower.indexOf('0x');
    if (idx != -1) {
      var sub = lower.substring(idx);
      // Trim trailing non-hex chars
      final hexChars = RegExp(r'^[0-9a-fx]+');
      final m = hexChars.firstMatch(sub);
      if (m != null) {
        sub = m.group(0) ?? sub;
        if (sub.startsWith('0x')) sub = sub.substring(2);
        if (sub.length == 6) sub = 'FF$sub';
        if (sub.length >= 8) {
          final intVal = int.tryParse(sub.substring(0, 8), radix: 16);
          if (intVal != null) return Color(intVal);
        }
      }
    }

    // 3) As a last resort, try to match any MaterialColor primary by toString equality
    //    (useful if some code persisted mat.toString()).
    for (final mc in Colors.primaries) {
      if (mc.toString() == v) {
        return mc; // MaterialColor extends Color
      }
    }

    return null;
  }

  static String _toHex(Color c) {
    final a =
        ((c.a * 255.0).round() & 0xff)
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
    final r =
        ((c.r * 255.0).round() & 0xff)
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
    final g =
        ((c.g * 255.0).round() & 0xff)
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
    final b =
        ((c.b * 255.0).round() & 0xff)
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
    return '#$a$r$g$b';
  }

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
          theme_color: prefs.getString(_kThemeColor) ?? '#FF2196F3', // blue
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
    // Ensure theme color is a valid hex or known name; normalize to hex
    final parsed = _tryParseColor(state.theme_color);
    if (parsed == null) {
      final fallback = Colors.blue;
      final hex = _toHex(fallback);
      state = state.copyWith(theme_color: hex);
      prefs.setString(_kThemeColor, hex);
    } else {
      final hex = _toHex(parsed);
      if (state.theme_color != hex) {
        state = state.copyWith(theme_color: hex);
        prefs.setString(_kThemeColor, hex);
      }
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

  Future<void> setThemeColor(String themeColor) async {
    // Accept hex like '#FF2196F3', '#2196F3', or known names like 'blue'. Normalize to hex.
    final c = _tryParseColor(themeColor) ?? Colors.blue;
    final hex = _toHex(c);
    state = state.copyWith(theme_color: hex);
    await prefs.setString(_kThemeColor, hex);
  }

  Future<void> resetToDefaults() async {
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    final normalized = _normalizeLanguageTag(device);
    state = PreferencesState(
      theme: 'system',
      language: normalized,
      exportDpi: 144.0,
      theme_color: '#FF2196F3',
    );
    await prefs.setString(_kTheme, 'system');
    await prefs.setString(_kLanguage, normalized);
    await prefs.setString(_kPageView, 'continuous');
    await prefs.setDouble(_kExportDpi, 144.0);
    await prefs.setString(_kThemeColor, '#FF2196F3');
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

/// Maps the selected theme color name to an actual Color for theming.
final themeSeedColorProvider = Provider<Color>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  final c = PreferencesStateNotifier._tryParseColor(prefs.theme_color);
  return c ?? Colors.blue;
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
