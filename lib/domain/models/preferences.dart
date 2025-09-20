import 'package:freezed_annotation/freezed_annotation.dart';

part 'preferences.freezed.dart';
part 'preferences.g.dart';

/// Immutable preferences model with JSON support
@freezed
abstract class PreferencesState with _$PreferencesState {
  const factory PreferencesState({
    @Default('system') String theme, // 'light' | 'dark' | 'system'
    @Default('#FF2196F3') String theme_color, // hex ARGB string
    @Default('en') String language, // BCP-47 tag like 'en'|'zh-TW'
    @Default(144.0) double exportDpi, // 96.0 | 144.0 | 200.0 | 300.0
  }) = _PreferencesState;

  factory PreferencesState.fromJson(Map<String, dynamic> json) =>
      _$PreferencesStateFromJson(json);
}
