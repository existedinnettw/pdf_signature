import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/model.dart';

class SignatureCardStateNotifier extends StateNotifier<List<SignatureCard>> {
  SignatureCardStateNotifier() : super(const []);

  void add(SignatureCard card) {
    state = List.of(state)..add(card);
  }

  void addWithAsset(SignatureAsset asset, double rotationDeg) {
    state = List.of(state)
      ..add(SignatureCard(asset: asset, rotationDeg: rotationDeg));
  }

  void update(
    SignatureCard card,
    double? rotationDeg,
    GraphicAdjust? graphicAdjust,
  ) {
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

final signatureCardRepositoryProvider =
    StateNotifierProvider<SignatureCardStateNotifier, List<SignatureCard>>(
      (ref) => SignatureCardStateNotifier(),
    );
