import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:file_selector/file_selector.dart' as fs;

import 'package:pdf_signature/data/services/export_service.dart';

import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_export_view_model.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pages_sidebar.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

class RecordingExporter extends ExportService {
  bool called = false;
  @override
  Future<bool> saveBytesToFile({required bytes, required outputPath}) async {
    called = true;
    return true;
  }
}

// Lightweight fake exporter to avoid invoking heavy rasterization during tests
class LightweightExporter extends ExportService {
  @override
  Future<Uint8List?> exportSignedPdfFromBytes({
    required Uint8List srcBytes,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    Map<String, Uint8List>? libraryBytes,
    double targetDpi = 144.0,
  }) async {
    // Return minimal non-empty bytes; content isn't used further in tests
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<bool> saveBytesToFile({
    required Uint8List bytes,
    required String outputPath,
  }) async {
    return true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
    final fake = RecordingExporter();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // For this test, we don't need the PDF bytes since it's not loaded
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) => DocumentStateNotifier()..openPicked(pageCount: 3),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
          pdfExportViewModelProvider.overrideWith(
            (ref) => PdfExportViewModel(
              ref,
              exporter: fake,
              savePathPicker: () async {
                final dir = Directory.systemTemp.createTempSync('pdfsig_');
                return '${dir.path}/output.pdf';
              },
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
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
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPicked(pageCount: 3, bytes: pdfBytes),
          ),
          signatureAssetRepositoryProvider.overrideWith((ref) {
            final c = SignatureAssetRepository();
            c.add(sigBytes, name: 'image');
            return c;
          }),
          signatureCardRepositoryProvider.overrideWith((ref) {
            final cardRepo = SignatureCardStateNotifier();
            final asset = SignatureAsset(bytes: sigBytes, name: 'image');
            cardRepo.addWithAsset(asset, 0.0);
            return cardRepo;
          }),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
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
    final r = container.read(pdfViewModelProvider).activeRect!;
    final lib = container.read(signatureAssetRepositoryProvider);
    final asset = lib.isNotEmpty ? lib.first : null;
    final currentPage = container.read(pdfViewModelProvider).currentPage;
    container
        .read(documentRepositoryProvider.notifier)
        .addPlacement(page: currentPage, rect: r, asset: asset);
    // Clear active overlay by hiding signatures temporarily
    // Note: signatureVisibilityProvider was removed in migration
    // container.read(signatureVisibilityProvider.notifier).state = false;
    await tester.pump();
    // container.read(signatureVisibilityProvider.notifier).state = true;
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

  // ---- PDF view interaction tests (merged from pdf_view_test.dart) ----
  testWidgets('PDF View: programmatic page jumps reach last page', (
    tester,
  ) async {
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPicked(pageCount: 3, bytes: pdfBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    expect(container.read(pdfViewModelProvider).currentPage, 1);
    container.read(pdfViewModelProvider.notifier).jumpToPage(2);
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 2);
    container.read(pdfViewModelProvider.notifier).jumpToPage(3);
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 3);
  });

  testWidgets('PDF View: zoom in/out', (tester) async {
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPicked(pageCount: 3, bytes: pdfBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pdfViewer = find.byKey(const ValueKey('pdf_page_area'));
    expect(pdfViewer, findsOneWidget);
    final center = tester.getCenter(pdfViewer);
    final g1 = await tester.createGesture();
    final g2 = await tester.createGesture();
    await g1.down(center - const Offset(10, 0));
    await g2.down(center + const Offset(10, 0));
    await g1.moveTo(center - const Offset(20, 0));
    await g2.moveTo(center + const Offset(20, 0));
    await g1.up();
    await g2.up();
    await tester.pumpAndSettle();
    expect(pdfViewer, findsOneWidget);
  });

  testWidgets('PDF View: jump to page by clicking thumbnail', (tester) async {
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPicked(pageCount: 3, bytes: pdfBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    expect(container.read(pdfViewModelProvider).currentPage, 1);

    final pagesSidebar = find.byType(PagesSidebar);
    expect(pagesSidebar, findsOneWidget);

    // Scroll to make page 3 thumbnail visible
    await tester.drag(pagesSidebar, const Offset(0, -300));
    await tester.pumpAndSettle();

    final page3Thumb = find.text('3');
    expect(page3Thumb, findsOneWidget);
    await tester.tap(page3Thumb);
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 3);
  });

  testWidgets('PDF View: thumbnails scroll and select', (tester) async {
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPicked(pageCount: 3, bytes: pdfBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    expect(container.read(pdfViewModelProvider).currentPage, 1);
    final sidebar = find.byType(PagesSidebar);
    expect(sidebar, findsOneWidget);
    await tester.drag(sidebar, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(container.read(pdfViewModelProvider).currentPage, 1);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 2);
  });

  testWidgets('PDF View: tap viewer after export does not crash', (
    tester,
  ) async {
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPicked(pageCount: 3, bytes: pdfBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
          pdfExportViewModelProvider.overrideWith(
            (ref) => PdfExportViewModel(
              ref,
              exporter: LightweightExporter(),
              savePathPicker: () async {
                final dir = Directory.systemTemp.createTempSync(
                  'pdfsig_after_',
                );
                return '${dir.path}/output-after-export.pdf';
              },
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile('test.pdf'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger export
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();

    // Tap on the page area; should not crash
    final pageArea = find.byKey(const ValueKey('pdf_page_area'));
    expect(pageArea, findsOneWidget);
    await tester.tap(pageArea);
    await tester.pumpAndSettle();

    // Still present and responsive
    expect(pageArea, findsOneWidget);
  });
}
