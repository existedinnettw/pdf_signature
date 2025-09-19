import 'dart:math' as math;

/// Convert degrees to radians with counterclockwise as positive in screen space
/// by inverting the sign (because screen Y axis points downwards).
double ccwRadians(double degrees) => -degrees * math.pi / 180.0;

/// Classic math convention: positive degrees rotate counterclockwise.
/// No screen-space Y-inversion applied.
double radians(double degrees) => degrees * math.pi / 180.0;

/// Compute scale factor to keep a rotated rectangle of aspect ratio [ar]
/// within a unit 1x1 box. If [ar] is null or <= 0, fall back to a square.
/// Returns the scale to apply before rotation.
double scaleToFitForAngle(double angleRad, {double? ar}) {
  final double c = angleRad == 0.0 ? 1.0 : math.cos(angleRad).abs();
  final double s = angleRad == 0.0 ? 0.0 : math.sin(angleRad).abs();
  if (ar != null && ar > 0) {
    return math.min(ar / (ar * c + s), 1.0 / (ar * s + c));
  }
  return 1.0 / (c + s).clamp(1.0, double.infinity);
}
