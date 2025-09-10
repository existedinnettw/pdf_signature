import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/domain/models/model.dart';

///
class SignatureAssetRepository extends StateNotifier<List<SignatureAsset>> {
  SignatureAssetRepository() : super(const []);

  String add(Uint8List bytes, {String? name}) {
    // Always add a new asset (allow duplicates). This lets users create multiple cards
    // even when loading the same image repeatedly for different adjustments/usages.
    if (bytes.isEmpty) return '';
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    state = List.of(state)
      ..add(SignatureAsset(id: id, bytes: bytes, name: name));
    return id;
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList(growable: false);
  }

  SignatureAsset? byId(String id) {
    for (final a in state) {
      if (a.id == id) return a;
    }
    return null;
  }
}

final signatureAssetRepositoryProvider =
    StateNotifierProvider<SignatureAssetRepository, List<SignatureAsset>>(
      (ref) => SignatureAssetRepository(),
    );
