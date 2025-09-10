import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesViewModel {
  final Ref ref;

  PreferencesViewModel(this.ref);

  // Add methods as needed
}

final preferencesViewModelProvider = Provider<PreferencesViewModel>((ref) {
  return PreferencesViewModel(ref);
});
