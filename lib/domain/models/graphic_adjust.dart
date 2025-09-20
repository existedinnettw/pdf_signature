import 'package:freezed_annotation/freezed_annotation.dart';

part 'graphic_adjust.freezed.dart';

@freezed
abstract class GraphicAdjust with _$GraphicAdjust {
  const factory GraphicAdjust({
    @Default(1.0) double contrast,
    @Default(1.0) double brightness,
    @Default(false) bool bgRemoval,
  }) = _GraphicAdjust;
}
