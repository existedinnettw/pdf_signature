/// TODO: add `freeze` and `json_serializable` to generate immutable data class with copyWith, toString, equality, and JSON support.
class PreferencesState {
  final String theme; // 'light' | 'dark' | 'system'
  final String theme_color; // 'blue' | 'green' | 'red' | 'purple'
  final String language; // 'en' | 'zh-TW' | 'es'
  final double exportDpi; // 96.0 | 144.0 | 200.0 | 300.0
  const PreferencesState({
    required this.theme,
    required this.theme_color,
    required this.language,
    required this.exportDpi,
  });

  PreferencesState copyWith({
    String? theme,
    String? theme_color,
    String? language,
    double? exportDpi,
  }) => PreferencesState(
    theme: theme ?? this.theme,
    theme_color: theme_color ?? this.theme_color,
    language: language ?? this.language,
    exportDpi: exportDpi ?? this.exportDpi,
  );
}
