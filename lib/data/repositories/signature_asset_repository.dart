import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/domain/models/model.dart';

///
class SignatureAssetRepository extends StateNotifier<List<SignatureAsset>> {
  SignatureAssetRepository() : super(const []);

  void add(Uint8List bytes, {String? name}) {
    // Always add a new asset (allow duplicates). This lets users create multiple cards
    // even when loading the same image repeatedly for different adjustments/usages.
    if (bytes.isEmpty) return;
    state = List.of(state)..add(SignatureAsset(bytes: bytes, name: name));
  }

  void remove(SignatureAsset asset) {
    state = state.where((a) => a != asset).toList(growable: false);
  }
}

final signatureAssetRepositoryProvider =
    StateNotifierProvider<SignatureAssetRepository, List<SignatureAsset>>(
      (ref) => SignatureAssetRepository(),
    );
