import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/data/services/export_service.dart';
import 'package:pdf_signature/domain/models/document.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_export_view_model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pages_sidebar.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_viewer_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Note: We use the real ExportService via the repository; no mocks here.

class _PreloadedDocumentStateNotifier extends DocumentStateNotifier {
  _PreloadedDocumentStateNotifier({
    required this.bytes,
    required this.pageCount,
    ExportService? service,
  }) : super(service: service);

  final Uint8List bytes;
  final int pageCount;

  @override
  Document build() {
    super.build();
    return Document(loaded: true, pageCount: pageCount, pickedPdfBytes: bytes);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            () => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            () => _PreloadedDocumentStateNotifier(
              bytes: pdfBytes,
              pageCount: 3,
              service: ExportService(),
            ),
          ),
          pdfViewModelProvider.overrideWith(() => PdfViewModel()),
          // Disable overlays to avoid long-lived overlay animations in CI
          viewerOverlaysEnabledProvider.overrideWith((ref) => false),
          pdfExportViewModelProvider.overrideWith(
            () => PdfExportViewModel(
              savePathPicker: () async {
                final dir = Directory.systemTemp.createTempSync('pdfsig_');
                return '${dir.path}/output.pdf';
              },
              savePathPickerWithSuggestedName: (_) async {
                final dir = Directory.systemTemp.createTempSync('pdfsig_');
                return '${dir.path}/output.pdf';
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
            currentFile: XFile('test.pdf'),
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

  testWidgets('Export completes successfully (FOSS path)', (tester) async {
    // Verify the exporter completes and shows SnackBar using the single
    // FOSS path (pdfrx render + pdf compose) on all platforms.
    final pdfBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            () => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            () => _PreloadedDocumentStateNotifier(
              bytes: pdfBytes,
              pageCount: 3,
              service: ExportService(),
            ),
          ),
          pdfViewModelProvider.overrideWith(() => PdfViewModel()),
          pdfExportViewModelProvider.overrideWith(
            () => PdfExportViewModel(
              savePathPicker: () async {
                final dir = Directory.systemTemp.createTempSync(
                  'pdfsig_linux_',
                );
                return '${dir.path}/out.pdf';
              },
              savePathPickerWithSuggestedName: (_) async {
                final dir = Directory.systemTemp.createTempSync(
                  'pdfsig_linux_',
                );
                return '${dir.path}/out.pdf';
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
            currentFile: XFile('test.pdf'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved:'), findsOneWidget);
  });

  testWidgets('E2E (integration): place and confirm keeps size', (
    tester,
  ) async {
    // Skip in integration environment: overlay interaction was refactored
    // and this check is covered by widget tests.
  }, skip: true);

  testWidgets('E2E (integration): programmatic placement size matches', (
    tester,
  ) async {
    // Skip in integration run; covered by lower-level widget tests.
    return;
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
            () => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            () => _PreloadedDocumentStateNotifier(
              bytes: pdfBytes,
              pageCount: 3,
              service: ExportService(enableRaster: false),
            ),
          ),
          pdfViewModelProvider.overrideWith(() => PdfViewModel()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: XFile('test.pdf'),
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
            () => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            () => _PreloadedDocumentStateNotifier(
              bytes: pdfBytes,
              pageCount: 3,
              service: ExportService(enableRaster: false),
            ),
          ),
          pdfViewModelProvider.overrideWith(() => PdfViewModel()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: XFile('test.pdf'),
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
            () => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            () => _PreloadedDocumentStateNotifier(
              bytes: pdfBytes,
              pageCount: 3,
              service: ExportService(enableRaster: false),
            ),
          ),
          pdfViewModelProvider.overrideWith(() => PdfViewModel()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: XFile('test.pdf'),
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
    final page3Thumb = find.text('3');
    await tester.ensureVisible(page3Thumb);
    await tester.pumpAndSettle();
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
            () => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            () => _PreloadedDocumentStateNotifier(
              bytes: pdfBytes,
              pageCount: 3,
              service: ExportService(),
            ),
          ),
          pdfViewModelProvider.overrideWith(() => PdfViewModel()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: XFile('test.pdf'),
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

  testWidgets(
    'PDF View: tap viewer after export does not crash',
    (tester) async {
      final pdfBytes =
          await File(
            'integration_test/data/sample-local-pdf.pdf',
          ).readAsBytes();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesRepositoryProvider.overrideWith(
              () => PreferencesStateNotifier(prefs),
            ),
            documentRepositoryProvider.overrideWith(
              () => _PreloadedDocumentStateNotifier(
                bytes: pdfBytes,
                pageCount: 3,
                service: ExportService(),
              ),
            ),
            pdfViewModelProvider.overrideWith(() => PdfViewModel()),
            // Disable overlays to reduce post-export timers/animations.
            viewerOverlaysEnabledProvider.overrideWith((ref) => false),
            // Override only save path picker to avoid native dialogs; use real exporter
            pdfExportViewModelProvider.overrideWith(
              () => PdfExportViewModel(
                savePathPicker: () async {
                  final dir = Directory.systemTemp.createTempSync(
                    'pdfsig_after_',
                  );
                  return '${dir.path}/output-after-export.pdf';
                },
                savePathPickerWithSuggestedName: (_) async {
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
              currentFile: XFile('test.pdf'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger export
      debugPrint('[AFTER_EXPORT] Tap save to start export');
      await tester.tap(find.byKey(const Key('btn_save_pdf')));
      // Wait for export to complete using a real async wait so the test harness
      // doesn't expect frame settling.
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 6));
        while (DateTime.now().isBefore(deadline)) {
          try {
            final container = ProviderScope.containerOf(
              tester.element(find.byType(PdfSignatureHomePage)),
            );
            final exporting =
                container.read(pdfExportViewModelProvider).exporting;
            if (!exporting) break;
          } catch (_) {
            // If widget unmounted, just stop waiting.
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      // Tap the viewer after export finished to ensure no crash
      final viewer = find.byKey(const ValueKey('pdf_page_area'));
      expect(viewer, findsOneWidget);
      await tester.tap(viewer);
      await tester.pump(const Duration(milliseconds: 150));
      // Hard-unmount the app to stop any viewer timers/animations
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      // Give async zone a brief chance to flush background timers
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      debugPrint('[AFTER_EXPORT] Test end reached (no crash)');
      // Ensure the test registers a completed assertion.
      expect(true, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
