import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;

import 'package:pdf_signature/data/services/export_service.dart';
import 'package:pdf_signature/data/services/export_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

class RecordingExporter extends ExportService {
  bool called = false;
  @override
  Future<bool> saveBytesToFile({required bytes, required outputPath}) async {
    called = true;
    return true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
    final fake = RecordingExporter();
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
          exportServiceProvider.overrideWith((_) => fake),
          savePathPickerProvider.overrideWith(
            (_) => () async => 'C:/tmp/output.pdf',
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PdfSignatureHomePage(),
        ),
      ),
    );
    await tester.pump();

    // Trigger save directly
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();

    // Expect success UI
    expect(find.textContaining('Saved:'), findsOneWidget);
  });

  // Helper to build a simple in-memory PNG as a signature image
  Uint8List _makeSig() {
    final canvas = img.Image(width: 80, height: 40);
    img.fill(canvas, color: img.ColorUint8.rgb(255, 255, 255));
    img.drawLine(
      canvas,
      x1: 6,
      y1: 20,
      x2: 74,
      y2: 20,
      color: img.ColorUint8.rgb(0, 0, 0),
    );
    return Uint8List.fromList(img.encodePng(canvas));
  }

  testWidgets('E2E (integration): place and confirm keeps size', (
    tester,
  ) async {
    final sigBytes = _makeSig();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfProvider.overrideWith(
            (ref) => PdfController()..openPicked(path: 'test.pdf'),
          ),
          signatureLibraryProvider.overrideWith((ref) {
            final c = SignatureLibraryController();
            c.add(sigBytes, name: 'image');
            return c;
          }),
          // Keep mock viewer for determinism on CI/desktop devices
          useMockViewerProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PdfSignatureHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('gd_signature_card_area')).first;
    await tester.tap(card);
    await tester.pump();

    final active = find.byKey(const Key('signature_overlay'));
    expect(active, findsOneWidget);
    final sizeBefore = tester.getSize(active);

    await tester.ensureVisible(active);
    await tester.pumpAndSettle();
    // Programmatically simulate confirm: add placement with current rect and bound image, then clear active overlay.
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final sigState = container.read(signatureProvider);
    final r = sigState.rect!;
    final Size pageSize = SignatureController.pageSize;
    final normalized = Rect.fromLTWH(
      (r.left / pageSize.width).clamp(0.0, 1.0),
      (r.top / pageSize.height).clamp(0.0, 1.0),
      (r.width / pageSize.width).clamp(0.0, 1.0),
      (r.height / pageSize.height).clamp(0.0, 1.0),
    );
    final lib = container.read(signatureLibraryProvider);
    final imageId = lib.isNotEmpty ? lib.first.id : 'default.png';
    final pdf = container.read(pdfProvider);
    container
        .read(pdfProvider.notifier)
        .addPlacement(page: pdf.currentPage, rect: normalized, image: imageId);
    container.read(signatureProvider.notifier).clearActiveOverlay();
    await tester.pumpAndSettle();

    final placed = find.byKey(const Key('placed_signature_0'));
    expect(placed, findsOneWidget);
    final sizeAfter = tester.getSize(placed);

    expect(
      (sizeAfter.width - sizeBefore.width).abs() < sizeBefore.width * 0.15,
      isTrue,
    );
    expect(
      (sizeAfter.height - sizeBefore.height).abs() < sizeBefore.height * 0.15,
      isTrue,
    );
  });
}
