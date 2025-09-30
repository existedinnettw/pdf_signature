import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'package:cross_file/cross_file.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pages_sidebar.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

/// It has known that sample-local-pdf.pdf has 3 pages.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
                  ..openPickedWithPageCount(pageCount: 3, bytes: pdfBytes),
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
            currentFile: XFile('test.pdf'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Extra settle to avoid startup race when running with other integration tests.
    await tester.pump(const Duration(milliseconds: 200));

    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final vm = container.read(pdfViewModelProvider);
    expect(vm.currentPage, 1);

    final controller = container.read(pdfViewModelProvider).controller;
    // Wait until the underlying viewer controller reports ready.
    final readyStart = DateTime.now();
    while (!controller.isReady) {
      await tester.pump(const Duration(milliseconds: 40));
      if (DateTime.now().difference(readyStart) > const Duration(seconds: 5)) {
        fail('PdfViewerController never became ready');
      }
    }
    Future<void> goAndAwait(int target) async {
      controller.goToPage(pageNumber: target);
      final start = DateTime.now();
      while (container.read(pdfViewModelProvider).currentPage != target) {
        await tester.pump(const Duration(milliseconds: 40));
        if (DateTime.now().difference(start) > const Duration(seconds: 3)) {
          fail(
            'Timeout waiting to reach page $target (current=${container.read(pdfViewModelProvider).currentPage})',
          );
        }
      }
    }

    await goAndAwait(2);
    expect(container.read(pdfViewModelProvider).currentPage, 2);
    await goAndAwait(3);
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
                  ..openPickedWithPageCount(pageCount: 3, bytes: pdfBytes),
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
            currentFile: XFile('test.pdf'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 120));

    final pdfViewer = find.byKey(const ValueKey('pdf_page_area'));
    expect(pdfViewer, findsOneWidget);

    final center = tester.getCenter(pdfViewer);
    final gesture1 = await tester.createGesture();
    final gesture2 = await tester.createGesture();
    await gesture1.down(center - const Offset(10, 0));
    await gesture2.down(center + const Offset(10, 0));
    await gesture1.moveTo(center - const Offset(20, 0));
    await gesture2.moveTo(center + const Offset(20, 0));
    await gesture1.up();
    await gesture2.up();
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
                  ..openPickedWithPageCount(pageCount: 3, bytes: pdfBytes),
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

    // Helper to read the background color of a thumbnail tile by page label
    Color? tileBgForPage(int page) {
      final pageLabel = find.descendant(
        of: pagesSidebar,
        matching: find.text('$page'),
      );
      if (pageLabel.evaluate().isEmpty) return null; // not visible yet
      final decoratedAncestors = find.ancestor(
        of: pageLabel,
        matching: find.byType(DecoratedBox),
      );
      final decoratedBoxes =
          decoratedAncestors
              .evaluate()
              .map((e) => e.widget)
              .whereType<DecoratedBox>()
              .toList();
      for (final d in decoratedBoxes) {
        final dec = d.decoration;
        if (dec is BoxDecoration && dec.color != null) {
          return dec.color;
        }
      }
      return null;
    }

    final theme = Theme.of(tester.element(pagesSidebar));
    // Initially, page 1 should be highlighted
    expect(tileBgForPage(1), theme.colorScheme.primaryContainer);

    // Scroll to make page 3 thumbnail visible
    await tester.drag(pagesSidebar, const Offset(0, -300));
    await tester.pumpAndSettle();

    final page3Thumbnail = find.text('3');
    expect(page3Thumbnail, findsOneWidget);
    await tester.tap(page3Thumbnail);
    await tester.pumpAndSettle();

    expect(container.read(pdfViewModelProvider).currentPage, 3);
    // After navigation completes, page 3 should be highlighted
    expect(tileBgForPage(3), theme.colorScheme.primaryContainer);
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
                  ..openPickedWithPageCount(pageCount: 3, bytes: pdfBytes),
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

    await tester.drag(pagesSidebar, const Offset(0, -200));
    await tester.pumpAndSettle();

    // Page number '1' may appear in multiple text widgets (e.g., overlay/toolbar); restrict to sidebar.
    final page1InSidebar = find.descendant(
      of: pagesSidebar,
      matching: find.text('1'),
    );
    expect(page1InSidebar, findsOneWidget);
    expect(container.read(pdfViewModelProvider).currentPage, 1);

    // Select page 2 thumbnail and verify page changes
    final page2InSidebar = find.descendant(
      of: pagesSidebar,
      matching: find.text('2'),
    );
    await tester.tap(page2InSidebar);
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 2);
  });

  testWidgets('PDF View: scroll thumb to reveal and select last page', (
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
                  ..openPickedWithPageCount(pageCount: 3, bytes: pdfBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
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

    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    expect(container.read(pdfViewModelProvider).currentPage, 1);

    final pagesSidebar = find.byType(PagesSidebar);
    expect(pagesSidebar, findsOneWidget);

    // Ensure page 3 not initially in view by trying to find it and allowing that it might be offstage.
    // Perform a scroll/drag to bring page 3 into view.
    await tester.drag(pagesSidebar, const Offset(0, -400));
    await tester.pumpAndSettle();

    final page3 = find.descendant(of: pagesSidebar, matching: find.text('3'));
    expect(page3, findsOneWidget);
    await tester.tap(page3);
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 3);

    // Scroll back upward and verify selection persists.
    await tester.drag(pagesSidebar, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(container.read(pdfViewModelProvider).currentPage, 3);
  });

  testWidgets('PDF View: reopen another PDF via toolbar picker updates viewer', (
    tester,
  ) async {
    final initialBytes =
        await File('integration_test/data/sample-local-pdf.pdf').readAsBytes();
    // 3 pages
    final newBytes =
        await File(
          'integration_test/data/PPFZ-Local-Purchase-Form.pdf',
        ).readAsBytes();
    // 10 pages
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // We'll override onPickPdf to simulate opening a new file with a different page count
    // TODO: Replace PPFZ-Local-Purchase-Form.pdf with a 10-page PDF to test page count change
    late ProviderContainer container; // capture to use inside callback
    Future<void> simulatePick() async {
      container
          .read(documentRepositoryProvider.notifier)
          .openPicked(bytes: newBytes);
      // Reset the current page explicitly to 1 as openPicked establishes new doc
      container.read(pdfViewModelProvider.notifier).jumpToPage(1);
    }

    int? lastDocPageCount; // capture page count from callback
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()
                  ..openPickedWithPageCount(pageCount: 3, bytes: initialBytes),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: false),
          ),
        ],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: PdfSignatureHomePage(
                onPickPdf: simulatePick,
                onClosePdf: () {},
                currentFile: XFile('initial.pdf'),
                // The only reliable way to detect the new document load correctly
                onDocumentChanged: (doc) {
                  if (doc != null) {
                    lastDocPageCount = doc.pages.length;
                  }
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Verify initial state Page 1/3
    expect(find.byKey(const Key('lbl_page_info')), findsOneWidget);
    final initialLabel =
        tester.widget<Text>(find.byKey(const Key('lbl_page_info'))).data;
    expect(initialLabel, contains('/3'));

    // Tap open picker button to simulate opening new PDF
    await tester.tap(find.byKey(const Key('btn_open_pdf_picker')));
    // Allow frame to process state changes from simulatePick
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // Wait for async page count detection to complete in repository
    await tester.runAsync(() async {
      final start = DateTime.now();
      while (container.read(documentRepositoryProvider).pageCount != 10) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();

        if (DateTime.now().difference(start) > const Duration(seconds: 8)) {
          final pageCount =
              container.read(documentRepositoryProvider).pageCount;
          fail(
            'Timeout waiting for repository page count to update to 10 (current=$pageCount)',
          );
        }
      }

      // Wait for restoration mechanism to complete
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    final updatedLabel =
        tester.widget<Text>(find.byKey(const Key('lbl_page_info'))).data;
    expect(updatedLabel, contains('/10'));
    // Verify that repository correctly analyzed PDF bytes and updated page count
    expect(container.read(documentRepositoryProvider).pageCount, 10);
    expect(lastDocPageCount, 10);
    expect(container.read(pdfViewModelProvider).currentPage, 1);
  });
}
