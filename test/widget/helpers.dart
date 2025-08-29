import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import 'package:pdf_signature/data/services/providers.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

Future<void> pumpWithOpenPdf(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdfProvider.overrideWith(
          (ref) => PdfController()..openPicked(path: 'test.pdf'),
        ),
        useMockViewerProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PdfSignatureHomePage(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpWithOpenPdfAndSig(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdfProvider.overrideWith(
          (ref) => PdfController()..openPicked(path: 'test.pdf'),
        ),
        signatureProvider.overrideWith(
          (ref) => SignatureController()..placeDefaultRect(),
        ),
        useMockViewerProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PdfSignatureHomePage(),
      ),
    ),
  );
  await tester.pump();
}
