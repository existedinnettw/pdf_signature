import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_page_area.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/domain/models/model.dart';

class _TestPdfController extends DocumentStateNotifier {
  _TestPdfController() : super() {
    state = Document.initial().copyWith(loaded: true, pageCount: 6);
  }
}

void main() {
  testWidgets(
    'PdfPageArea: continuous mode scrolls target page into view on jump',
    (tester) async {
      final ctrl = _TestPdfController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfViewModelProvider.overrideWith(
              (ref) => PdfViewModel(ref, useMockViewer: true),
            ),
            // Continuous mode is always-on; no page view override needed
            documentRepositoryProvider.overrideWith((ref) => ctrl),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  height: 520,
                  child: PdfPageArea(
                    pageSize: Size(676, 400),
                    controller: PdfViewerController(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Get initial scroll position (may already have auto-scrolled to current page)
      final listFinder = find.byKey(const Key('pdf_continuous_mock_list'));
      expect(listFinder, findsOneWidget);
      final scrollableFinder = find.descendant(
        of: listFinder,
        matching: find.byType(Scrollable),
      );
      double lastPixels =
          tester.state<ScrollableState>(scrollableFinder).position.pixels;

      final ctx = tester.element(find.byType(PdfPageArea));
      final container = ProviderScope.containerOf(ctx, listen: false);
      final vm = container.read(pdfViewModelProvider.notifier);

      Future<void> jumpAndVerify(int targetPage) async {
        final before = lastPixels;
        vm.jumpToPage(targetPage);
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        // Verify with viewport geometry
        final pageStack = find.byKey(ValueKey('page_stack_$targetPage'));
        expect(pageStack, findsOneWidget);

        final viewport = tester.getRect(listFinder);
        final pageRect = tester.getRect(pageStack);
        expect(
          viewport.overlaps(pageRect),
          isTrue,
          reason: 'Page $targetPage should overlap viewport after jump',
        );

        final currentPixels =
            tester.state<ScrollableState>(scrollableFinder).position.pixels;
        // Ensure scroll position changed (direction not enforced)
        expect(currentPixels, isNot(equals(before)));
        lastPixels = currentPixels;
      }

      // Jump to 4 different pages and verify each
      await jumpAndVerify(2);
      await jumpAndVerify(5);
      await jumpAndVerify(1);
      await jumpAndVerify(6);
      await jumpAndVerify(3);
    },
  );
}

// No extra callbacks required in the new API
