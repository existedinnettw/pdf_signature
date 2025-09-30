import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_signature/routing/router.dart';

class WelcomeViewModel {
  final Ref ref;
  final GoRouter router;

  WelcomeViewModel(this.ref, this.router);

  Future<void> openPdf({required String path, Uint8List? bytes}) async {
    // Return early if no bytes provided - can't open PDF without data
    if (bytes == null) {
      debugPrint(
        '[WelcomeViewModel] Cannot open PDF: no bytes provided for $path',
      );
      return;
    }

    // Use PdfSessionViewModel to open and navigate.
    final session = ref.read(pdfSessionViewModelProvider(router));
    await session.openPdf(path: path, bytes: bytes);
  }
}

final welcomeViewModelProvider = Provider<WelcomeViewModel>((ref) {
  final router = ref.read(routerProvider);
  return WelcomeViewModel(ref, router);
});
