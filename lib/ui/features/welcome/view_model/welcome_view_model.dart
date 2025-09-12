import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';

class WelcomeViewModel {
  final Ref ref;

  WelcomeViewModel(this.ref);

  Future<void> openPdf({required String path, Uint8List? bytes}) async {
    await ref
        .read(pdfViewModelProvider.notifier)
        .openPdf(path: path, bytes: bytes);
  }
}

final welcomeViewModelProvider = Provider<WelcomeViewModel>((ref) {
  return WelcomeViewModel(ref);
});
