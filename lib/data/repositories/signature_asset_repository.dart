import 'package:image/image.dart' as img;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/domain/models/model.dart';

///
class SignatureAssetRepository extends Notifier<List<SignatureAsset>> {
  @override
  List<SignatureAsset> build() => const [];

  /// Preferred API: add from an already decoded image to avoid re-decodes.
  void addImage(img.Image image, {String? name}) {
    state = List.of(state)..add(SignatureAsset(sigImage: image, name: name));
  }

  void remove(SignatureAsset asset) {
    state = state.where((a) => a != asset).toList(growable: false);
  }
}

final signatureAssetRepositoryProvider =
    NotifierProvider<SignatureAssetRepository, List<SignatureAsset>>(
      SignatureAssetRepository.new,
    );
