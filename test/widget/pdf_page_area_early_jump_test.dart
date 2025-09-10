import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_page_area.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/domain/models/model.dart';

class _TestPdfController extends DocumentStateNotifier {
  _TestPdfController() : super() {
    state = Document.initial().copyWith(
      loaded: true,
      pageCount: 6,
      currentPage: 1,
    );
  }
}

void main() {
  testWidgets('PdfPageArea: early jump queues and scrolls once list builds', (
    tester,
  ) async {
    final ctrl = _TestPdfController();

    // Build the widget tree
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useMockViewerProvider.overrideWithValue(true),
          // Continuous mode is always-on; no page view override needed
          documentRepositoryProvider.overrideWith((ref) => ctrl),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 520,
                child: PdfPageArea(
                  pageSize: Size(676, 400),
                  onDragSignature: _noopOffset,
                  onResizeSignature: _noopOffset,
                  onConfirmSignature: _noop,
                  onClearActiveOverlay: _noop,
                  onSelectPlaced: _noopInt,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Trigger an early jump immediately after first pump, before settle.
    ctrl.jumpTo(5);

    // Now allow frames to build and settle
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    // Validate that page 5 is in view and scroll offset moved.
    final listFinder = find.byKey(const Key('pdf_continuous_mock_list'));
    expect(listFinder, findsOneWidget);
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );
    final pos = tester.state<ScrollableState>(scrollableFinder).position;
    expect(pos.pixels, greaterThan(0));

    final pageStack = find.byKey(const ValueKey('page_stack_5'));
    expect(pageStack, findsOneWidget);
    final viewport = tester.getRect(listFinder);
    final pageRect = tester.getRect(pageStack);
    expect(viewport.overlaps(pageRect), isTrue);
  });
}

void _noop() {}
void _noopInt(int? _) {}
void _noopOffset(Offset _) {}
