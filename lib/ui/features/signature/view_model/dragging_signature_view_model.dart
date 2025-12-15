import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global flag indicating whether a signature card is currently being dragged.
class IsDraggingSignatureNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDragging(bool value) => state = value;
}

final isDraggingSignatureViewModelProvider =
    NotifierProvider<IsDraggingSignatureNotifier, bool>(
      IsDraggingSignatureNotifier.new,
    );
