class GraphicAdjust {
  final double contrast;
  final double brightness;
  final bool bgRemoval;

  const GraphicAdjust({
    this.contrast = 1.0,
    this.brightness = 0.0,
    this.bgRemoval = false,
  });

  GraphicAdjust copyWith({
    double? contrast,
    double? brightness,
    bool? bgRemoval,
  }) => GraphicAdjust(
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    bgRemoval: bgRemoval ?? this.bgRemoval,
  );
}
