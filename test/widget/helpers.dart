import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/ui_services.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
// preferences_providers.dart no longer exports pageViewModeProvider

Future<void> pumpWithOpenPdf(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWith(
          (ref) => DocumentStateNotifier()..openSample(),
        ),
        useMockViewerProvider.overrideWithValue(true),
        exportingProvider.overrideWith((ref) => false),
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
  final bytes = img.encodePng(canvas);
  // keep drawing for determinism even if bytes unused in simplified UI
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWith(
          (ref) => DocumentStateNotifier()..openSample(),
        ),
        signatureAssetRepositoryProvider.overrideWith((ref) {
          final repo = SignatureAssetRepository();
          repo.add(Uint8List.fromList(bytes), name: 'test');
          return repo;
        }),
        // In new model, interactive overlay not implemented; keep library empty
        useMockViewerProvider.overrideWithValue(true),
        exportingProvider.overrideWith((ref) => false),
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
