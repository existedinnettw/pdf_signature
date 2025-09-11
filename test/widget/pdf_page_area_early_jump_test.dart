import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_page_area.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/domain/models/model.dart';

class _TestPdfController extends DocumentStateNotifier {
  _TestPdfController() : super() {
    state = Document.initial().copyWith(loaded: true, pageCount: 6);
  }
}

void main() {
  testWidgets('PdfPageArea: early jump before build still scrolls to page', (
    tester,
  ) async {
    final ctrl = _TestPdfController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useMockViewerProvider.overrideWithValue(true),
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

    // Jump to page 5 right away via view model
    final ctx = tester.element(find.byType(PdfPageArea));
    final container = ProviderScope.containerOf(ctx, listen: false);
    final vm = container.read(pdfViewModelProvider.notifier);
    vm.jumpToPage(5);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    final listFinder = find.byKey(const Key('pdf_continuous_mock_list'));
    expect(listFinder, findsOneWidget);
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
