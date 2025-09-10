import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../domain/models/model.dart';

class SignatureCardStateNotifier extends StateNotifier<List<SignatureCard>> {
  SignatureCardStateNotifier() : super(const []);

  add({required SignatureAsset asset, double rotationDeg = 0.0}) {
    state = List.of(state)
      ..add(SignatureCard(asset: asset, rotationDeg: rotationDeg));
  }

  void update({
    required SignatureCard card,
    double? rotationDeg,
    GraphicAdjust? graphicAdjust,
  }) {
    final list = List<SignatureCard>.of(state);
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c == card) {
        list[i] = c.copyWith(
          rotationDeg: rotationDeg ?? c.rotationDeg,
          graphicAdjust: graphicAdjust ?? c.graphicAdjust,
        );
        state = list;
        return;
      }
    }
  }

  void remove(SignatureCard card) {
    state = state.where((c) => c != card).toList(growable: false);
  }

  void clearAll() {
    state = const [];
  }
}

final signatureCardProvider =
    StateNotifierProvider<SignatureCardStateNotifier, List<SignatureCard>>(
      (ref) => SignatureCardStateNotifier(),
    );
