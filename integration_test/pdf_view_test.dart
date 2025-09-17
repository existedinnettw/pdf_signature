import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart' as fs;

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
    // Extra settle to avoid startup race when running with other integration tests.
    await tester.pump(const Duration(milliseconds: 200));

    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final vm = container.read(pdfViewModelProvider);
    expect(vm.currentPage, 1);

    container.read(pdfViewModelProvider.notifier).jumpToPage(2);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 120));
    expect(container.read(pdfViewModelProvider).currentPage, 2);

    container.read(pdfViewModelProvider.notifier).jumpToPage(3);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 120));
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

    final page3Thumbnail = find.text('3');
    expect(page3Thumbnail, findsOneWidget);
    await tester.tap(page3Thumbnail);
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

  testWidgets('PDF View: scroll thumbnails to reveal and select last page', (
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

  //TODO: Scroll Thumbs
}
