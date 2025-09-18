import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global flag indicating whether a signature card is currently being dragged.
final isDraggingSignatureViewModelProvider = StateProvider<bool>(
  (ref) => false,
);
