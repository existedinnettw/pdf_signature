import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import 'package:pdf_signature/data/services/export_providers.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
// preferences_providers.dart no longer exports pageViewModeProvider

Future<void> pumpWithOpenPdf(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdfProvider.overrideWith(
          (ref) => PdfController()..openPicked(path: 'test.pdf'),
        ),
        useMockViewerProvider.overrideWith((ref) => true),
        // Continuous mode is always-on; no page view override needed
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
  // Create a tiny sample signature image (PNG) for deterministic tests
  final canvas = img.Image(width: 60, height: 30);
  // White background
  img.fill(canvas, color: img.ColorUint8.rgb(255, 255, 255));
  // Black rectangle line as a "signature"
  img.drawLine(
    canvas,
    x1: 5,
    y1: 15,
    x2: 55,
    y2: 15,
    color: img.ColorUint8.rgb(0, 0, 0),
  );
  final sigBytes = Uint8List.fromList(img.encodePng(canvas));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdfProvider.overrideWith(
          (ref) => PdfController()..openPicked(path: 'test.pdf'),
        ),
        signatureProvider.overrideWith(
          (ref) =>
              SignatureController()
                ..setImageBytes(sigBytes)
                ..placeDefaultRect(),
        ),
        useMockViewerProvider.overrideWith((ref) => true),
        // Continuous mode is always-on; no page view override needed
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
