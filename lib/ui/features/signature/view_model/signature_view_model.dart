import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignatureViewModel {
  final Ref ref;

  SignatureViewModel(this.ref);

  // Add methods as needed
}

final signatureViewModelProvider = Provider<SignatureViewModel>((ref) {
  return SignatureViewModel(ref);
});
