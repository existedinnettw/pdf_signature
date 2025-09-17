import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/welcome/widgets/welcome_screen.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';

// PdfManager removed: responsibilities moved into PdfSessionViewModel.

final routerProvider = Provider<GoRouter>((ref) {
  // Determine initial location based on current document state.
  // Access the state via the provider (not via the notifier's protected .state).
  final docState = ref.read(documentRepositoryProvider);
  final initialLocation = docState.loaded ? '/pdf' : '/';
  // Session view model will be obtained inside each route builder; no shared
  // late variable (avoids LateInitializationError on rebuilds).

  final navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter router; // declare before use in builders

  router = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final sessionVm = ref.read(pdfSessionViewModelProvider(router));
          return WelcomeScreen(
            onPickPdf: () => sessionVm.pickAndOpenPdf(),
            onOpenPdf:
                ({String? path, Uint8List? bytes, String? fileName}) =>
                    sessionVm.openPdf(path: path, bytes: bytes),
          );
        },
      ),
      GoRoute(
        path: '/pdf',
        builder: (context, state) {
          final sessionVm = ref.read(pdfSessionViewModelProvider(router));
          return PdfSignatureHomePage(
            onPickPdf: () => sessionVm.pickAndOpenPdf(),
            onClosePdf: () => sessionVm.closePdf(),
            currentFile: sessionVm.currentFile,
          );
        },
      ),
    ],
    initialLocation: initialLocation,
  );

  return router;
});
