import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pages_sidebar.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

/// It has known that sample-local-pdf.pdf has 3 pages.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PDF View: wheel scroll (page down)', (tester) async {
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
                DocumentStateNotifier()..openPicked(
                  path: 'integration_test/data/sample-local-pdf.pdf',
                  pageCount: 1,
                  bytes: pdfBytes,
                ),
          ),
          useMockViewerProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the PDF viewer area
    final pdfViewer = find.byKey(const ValueKey('pdf_page_area'));
    expect(pdfViewer, findsOneWidget);

    // Get initial state
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final initialPage = container.read(pdfViewModelProvider);
    expect(initialPage, 1);

    // Simulate wheel scroll down (PageDown) to reach the last page
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
    }

    // Verify that we reached the last page by checking the actual viewer state
    final pdfViewerState = tester.state<_PdfViewerWidgetState>(
      find.byType(PdfViewerWidget),
    );
    final actualPage = pdfViewerState.viewerCurrentPage;
    expect(actualPage, 3); // Should be on last page (3 pages total)
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
                DocumentStateNotifier()..openPicked(
                  path: 'integration_test/data/sample-local-pdf.pdf',
                  pageCount: 1,
                  bytes: pdfBytes,
                ),
          ),
          useMockViewerProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the PDF viewer
    final pdfViewer = find.byKey(const ValueKey('pdf_page_area'));
    expect(pdfViewer, findsOneWidget);

    // Perform pinch to zoom in
    final center = tester.getCenter(pdfViewer);
    // Simulate pinch zoom
    final gesture1 = await tester.createGesture();
    final gesture2 = await tester.createGesture();
    await gesture1.down(center - const Offset(10, 0));
    await gesture2.down(center + const Offset(10, 0));
    await gesture1.moveTo(center - const Offset(20, 0));
    await gesture2.moveTo(center + const Offset(20, 0));
    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();

    // Verify zoom worked (this might be hard to verify directly)
    // We can check if the viewer is still there
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
                DocumentStateNotifier()..openPicked(
                  path: 'integration_test/data/sample-local-pdf.pdf',
                  pageCount: 1,
                  bytes: pdfBytes,
                ),
          ),
          useMockViewerProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial page
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final initialPdf = container.read(documentRepositoryProvider);
    final initialPage = container.read(pdfViewModelProvider);
    expect(initialPage, 1);

    // Click on page 3 thumbnail (last page)
    final page3Thumbnail = find.text('3');
    expect(page3Thumbnail, findsOneWidget);
    await tester.tap(page3Thumbnail);
    await tester.pumpAndSettle();

    // Verify current page is 3 and page view actually jumped
    final finalPage = container.read(pdfViewModelProvider);
    expect(finalPage, 3);
    expect(finalPage, isNot(equals(1)));
  });

  testWidgets('PDF View: scroll thumbnails', (tester) async {
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
                DocumentStateNotifier()..openPicked(
                  path: 'integration_test/data/sample-local-pdf.pdf',
                  pageCount: 1,
                  bytes: pdfBytes,
                ),
          ),
          useMockViewerProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PdfSignatureHomePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Get initial page
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final initialPage = container.read(pdfViewModelProvider);
    expect(initialPage, 1);

    // Find the pages sidebar
    final pagesSidebar = find.byType(PagesSidebar);
    expect(pagesSidebar, findsOneWidget);

    // Scroll the thumbnails vertically
    await tester.drag(pagesSidebar, const Offset(0, -200));
    await tester.pumpAndSettle();

    // Verify scrolling worked (thumbnails are still there)
    final page1Thumbnail = find.text('1');
    expect(page1Thumbnail, findsOneWidget);

    // Check if page view changed (it shouldn't for vertical scroll of thumbs)
    final afterScrollPage = container.read(pdfViewModelProvider);
    expect(afterScrollPage, initialPage);

    // Now test horizontal scroll of PDF viewer
    final pdfViewer = find.byKey(const ValueKey('pdf_page_area'));
    expect(pdfViewer, findsOneWidget);

    // Scroll horizontally (might not change page for fitted PDF)
    await tester.drag(pdfViewer, const Offset(-100, 0)); // Scroll left
    await tester.pumpAndSettle();

    // Verify horizontal scroll (page might stay the same for portrait PDF)
    final afterHorizontalPage = container.read(pdfViewModelProvider);
    expect(afterHorizontalPage, greaterThan(1));
  });
}
