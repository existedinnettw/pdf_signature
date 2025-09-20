import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/domain/models/model.dart' as domain;
import 'package:pdf_signature/data/repositories/signature_card_repository.dart'
    as repo;
import 'package:image/image.dart' as img;

class SignatureViewModel {
  final Ref ref;

  SignatureViewModel(this.ref);

  repo.DisplaySignatureData getDisplaySignatureData(
    domain.SignatureAsset asset,
    domain.GraphicAdjust adjust,
  ) {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    return notifier.getDisplayData(asset, adjust);
  }

  // New image-based accessors
  img.Image getProcessedImage(
    domain.SignatureAsset asset,
    domain.GraphicAdjust adjust,
  ) {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    return notifier.getProcessedImage(asset, adjust);
  }

  (img.Image image, List<double>? colorMatrix) getDisplayImage(
    domain.SignatureAsset asset,
    domain.GraphicAdjust adjust,
  ) {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    return notifier.getDisplayImage(asset, adjust);
  }

  void clearCache() {
    final notifier = ref.read(repo.signatureCardRepositoryProvider.notifier);
    notifier.clearProcessedCache();
  }
}

final signatureViewModelProvider = Provider<SignatureViewModel>((ref) {
  return SignatureViewModel(ref);
});
