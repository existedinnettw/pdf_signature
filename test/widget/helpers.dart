import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_state.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_export_view_model.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/signature_asset.dart';
import 'package:pdf_signature/domain/models/model.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
// preferences_providers.dart no longer exports pageViewModeProvider

// Test helper classes
class TestPdfViewModel extends PdfViewModel {
  @override
  PdfViewState build() {
    return PdfViewState.initial(useMockViewer: true);
  }
}

class TestDocumentStateNotifier extends DocumentStateNotifier {
  @override
  Document build() {
    // Initialize with sample document for tests, bypassing the parent build
    return Document.initial().copyWith(
      loaded: true,
      pageCount: 5,
      pickedPdfBytes: null,
      placementsByPage: <int, List<SignaturePlacement>>{},
    );
  }
}

class TestDocumentStateNotifierWithPlacements extends DocumentStateNotifier {
  final Uint8List pdfBytes;
  final List<int> signatureBytes;

  TestDocumentStateNotifierWithPlacements(this.pdfBytes, this.signatureBytes);

  @override
  Document build() {
    final image = img.decodeImage(Uint8List.fromList(signatureBytes))!;
    final asset = SignatureAsset(sigImage: image);

    return Document.initial().copyWith(
      loaded: true,
      pageCount: 5,
      pickedPdfBytes: pdfBytes,
      placementsByPage: {
        1: [
          SignaturePlacement(
            rect: const Rect.fromLTWH(0.1, 0.1, 0.3, 0.2),
            asset: asset,
          ),
        ],
      },
    );
  }
}

// Test notifier for SignatureCardRepository with pre-initialized card
class TestSignatureCardStateNotifier extends SignatureCardStateNotifier {
  final List<int> signatureBytes;

  TestSignatureCardStateNotifier(this.signatureBytes);
  @override
  List<SignatureCard> build() {
    // Initialize with a card already added
    final image = img.decodeImage(Uint8List.fromList(signatureBytes))!;
    final asset = SignatureAsset(sigImage: image, name: 'test');

    return [SignatureCard(asset: asset, rotationDeg: 0.0)];
  }
}

// Test notifier for SignatureAssetRepository with pre-loaded asset
class TestSignatureAssetRepository extends SignatureAssetRepository {
  final List<int> signatureBytes;

  TestSignatureAssetRepository(this.signatureBytes);
  @override
  List<SignatureAsset> build() {
    // Initialize with an asset already added
    final image = img.decodeImage(Uint8List.fromList(signatureBytes))!;
    return [SignatureAsset(sigImage: image, name: 'test')];
  }
}

Future<void> pumpWithOpenPdf(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWith(
          () => TestDocumentStateNotifier(),
        ),
        pdfViewModelProvider.overrideWith(() => TestPdfViewModel()),
        pdfExportViewModelProvider.overrideWith(() => PdfExportViewModel()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PdfSignatureHomePage(
          onPickPdf: () async {},
          onClosePdf: () {},
          currentFile: XFile(''),
        ),
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

  // Create minimal PDF bytes for testing (this is a very basic PDF structure)
  // This is just enough to make the PDF viewer work in tests
  final pdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, // %PDF-1.4
    0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, // 1 0 obj
    0x3C,
    0x3C,
    0x2F,
    0x54,
    0x79,
    0x70,
    0x65,
    0x20,
    0x2F,
    0x43,
    0x61,
    0x74,
    0x61,
    0x6C,
    0x6F,
    0x67,
    0x20,
    0x2F,
    0x50,
    0x61,
    0x67,
    0x65,
    0x73,
    0x20,
    0x32,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3E,
    0x3E,
    0x0A,
    0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
    0x32, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A,
    0x3C,
    0x3C,
    0x2F,
    0x54,
    0x79,
    0x70,
    0x65,
    0x20,
    0x2F,
    0x50,
    0x61,
    0x67,
    0x65,
    0x73,
    0x20,
    0x2F,
    0x43,
    0x6F,
    0x75,
    0x6E,
    0x74,
    0x20,
    0x31,
    0x20,
    0x2F,
    0x4B,
    0x69,
    0x64,
    0x73,
    0x20,
    0x5B,
    0x33,
    0x20,
    0x30,
    0x20,
    0x52,
    0x5D,
    0x3E,
    0x3E,
    0x0A,
    0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
    0x33, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A,
    0x3C,
    0x3C,
    0x2F,
    0x54,
    0x79,
    0x70,
    0x65,
    0x20,
    0x2F,
    0x50,
    0x61,
    0x67,
    0x65,
    0x20,
    0x2F,
    0x50,
    0x61,
    0x72,
    0x65,
    0x6E,
    0x74,
    0x20,
    0x32,
    0x20,
    0x30,
    0x20,
    0x52,
    0x20,
    0x2F,
    0x4D,
    0x65,
    0x64,
    0x69,
    0x61,
    0x42,
    0x6F,
    0x78,
    0x20,
    0x5B,
    0x30,
    0x20,
    0x30,
    0x20,
    0x36,
    0x31,
    0x32,
    0x20,
    0x37,
    0x39,
    0x32,
    0x5D,
    0x20,
    0x2F,
    0x43,
    0x6F,
    0x6E,
    0x74,
    0x65,
    0x6E,
    0x74,
    0x73,
    0x20,
    0x34,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3E,
    0x3E,
    0x0A,
    0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
    0x34, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A,
    0x3C,
    0x3C,
    0x2F,
    0x4C,
    0x65,
    0x6E,
    0x67,
    0x74,
    0x68,
    0x20,
    0x34,
    0x34,
    0x3E,
    0x3E,
    0x0A,
    0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x0A,
    0x42, 0x54, 0x0A, // BT
    0x2F, 0x46, 0x31, 0x20, 0x32, 0x34, 0x20, 0x54, 0x66, 0x0A, // /F1 24 Tf
    0x31,
    0x30,
    0x30,
    0x20,
    0x37,
    0x30,
    0x30,
    0x20,
    0x54,
    0x64,
    0x0A, // 100 700 Td
    0x28,
    0x54,
    0x65,
    0x73,
    0x74,
    0x20,
    0x50,
    0x44,
    0x46,
    0x29,
    0x20,
    0x54,
    0x6A,
    0x0A, // (Test PDF) Tj
    0x45, 0x54, 0x0A, // ET
    0x65, 0x6E, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x0A,
    0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A,
    0x78, 0x72, 0x65, 0x66, 0x0A,
    0x30, 0x20, 0x35, 0x0A,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6E,
    0x20,
    0x0A,
    0x30,
    0x30,
    0x30,
    0x30,
    0x31,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6E,
    0x20,
    0x0A,
    0x30,
    0x30,
    0x30,
    0x30,
    0x32,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6E,
    0x20,
    0x0A,
    0x30,
    0x30,
    0x30,
    0x30,
    0x33,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6E,
    0x20,
    0x0A,
    0x30,
    0x30,
    0x30,
    0x30,
    0x34,
    0x20,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x20,
    0x6E,
    0x20,
    0x0A,
    0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72, 0x0A,
    0x3C,
    0x3C,
    0x2F,
    0x53,
    0x69,
    0x7A,
    0x65,
    0x20,
    0x35,
    0x20,
    0x2F,
    0x52,
    0x6F,
    0x6F,
    0x74,
    0x20,
    0x31,
    0x20,
    0x30,
    0x20,
    0x52,
    0x3E,
    0x3E,
    0x0A,
    0x73, 0x74, 0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66, 0x0A,
    0x35, 0x35, 0x39, 0x0A,
    0x25, 0x25, 0x45, 0x4F, 0x46, 0x0A, // %%EOF
  ]);

  // keep drawing for determinism even if bytes unused in simplified UI
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWith(
          () => TestDocumentStateNotifierWithPlacements(pdfBytes, bytes),
        ),
        signatureAssetRepositoryProvider.overrideWith(
          () => TestSignatureAssetRepository(bytes),
        ),
        signatureCardRepositoryProvider.overrideWith(
          () => TestSignatureCardStateNotifier(bytes),
        ),
        // In new model, interactive overlay not implemented; keep library empty
        pdfViewModelProvider.overrideWith(() => TestPdfViewModel()),
        pdfExportViewModelProvider.overrideWith(() => PdfExportViewModel()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PdfSignatureHomePage(
          onPickPdf: () async {},
          onClosePdf: () {},
          currentFile: XFile(''),
        ),
      ),
    ),
  );
  await tester.pump();
}
