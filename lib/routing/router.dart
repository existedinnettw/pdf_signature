import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/welcome/widgets/welcome_screen.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:pdfrx/pdfrx.dart';

class PdfManager {
  final DocumentStateNotifier _documentNotifier;
  final SignatureCardStateNotifier _signatureCardNotifier;
  final GoRouter _router;

  fs.XFile _currentFile = fs.XFile('');

  PdfManager({
    required DocumentStateNotifier documentNotifier,
    required SignatureCardStateNotifier signatureCardNotifier,
    required GoRouter router,
  }) : _documentNotifier = documentNotifier,
       _signatureCardNotifier = signatureCardNotifier,
       _router = router;

  fs.XFile get currentFile => _currentFile;

  Future<void> openPdf({String? path, Uint8List? bytes}) async {
    int pageCount = 1; // default
    if (bytes != null) {
      try {
        final doc = await PdfDocument.openData(bytes);
        pageCount = doc.pages.length;
      } catch (_) {
        // ignore
      }
    }

    // Update file reference if path is provided
    if (path != null) {
      _currentFile = fs.XFile(path);
    }

    _documentNotifier.openPicked(pageCount: pageCount, bytes: bytes);
    _signatureCardNotifier.clearAll();

    // Navigate to PDF screen after successfully opening PDF
    _router.go('/pdf');
  }

  void closePdf() {
    _documentNotifier.close();
    _signatureCardNotifier.clearAll();
    _currentFile = fs.XFile('');

    // Navigate back to welcome screen when closing PDF
    _router.go('/');
  }

  Future<void> pickAndOpenPdf() async {
    final typeGroup = const fs.XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }
      await openPdf(path: file.path, bytes: bytes);
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Create PdfManager instance with dependencies
  final documentNotifier = ref.read(documentRepositoryProvider.notifier);
  final signatureCardNotifier = ref.read(
    signatureCardRepositoryProvider.notifier,
  );

  // Create a late variable for the router
  late final GoRouter router;

  // Create PdfManager with router dependency (will be set after router creation)
  late final PdfManager pdfManager;

  // If tests pre-load a document, start at /pdf so sidebars and controls
  // are present immediately.
  final initialLocation = documentNotifier.debugState.loaded ? '/pdf' : '/';

  router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder:
            (context, state) => WelcomeScreen(
              onPickPdf: () => pdfManager.pickAndOpenPdf(),
              onOpenPdf:
                  ({String? path, Uint8List? bytes, String? fileName}) =>
                      pdfManager.openPdf(path: path, bytes: bytes),
            ),
      ),
      GoRoute(
        path: '/pdf',
        builder:
            (context, state) => PdfSignatureHomePage(
              onPickPdf: () => pdfManager.pickAndOpenPdf(),
              onClosePdf: () => pdfManager.closePdf(),
              currentFile: pdfManager.currentFile,
            ),
      ),
    ],
    initialLocation: initialLocation,
  );

  // Now create PdfManager with the router
  pdfManager = PdfManager(
    documentNotifier: documentNotifier,
    signatureCardNotifier: signatureCardNotifier,
    router: router,
  );

  return router;
});
