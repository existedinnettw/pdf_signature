import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/domain/models/model.dart' as domain;
import 'package:pdf_signature/data/repositories/signature_card_repository.dart'
    as repo;

class SignatureViewModel {
  final Ref ref;

  SignatureViewModel(this.ref);

  Uint8List getProcessedBytes(
    domain.SignatureAsset asset,
    domain.GraphicAdjust adjust,
  ) {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    return notifier.getProcessedBytes(asset, adjust);
  }

  repo.DisplaySignatureData getDisplaySignatureData(
    domain.SignatureAsset asset,
    domain.GraphicAdjust adjust,
  ) {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    return notifier.getDisplayData(asset, adjust);
  }

  void clearCache() {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    notifier.clearProcessedCache();
  }
}

final signatureViewModelProvider = Provider<SignatureViewModel>((ref) {
  return SignatureViewModel(ref);
});
