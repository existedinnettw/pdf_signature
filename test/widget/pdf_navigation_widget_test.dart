import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/data/model/model.dart';
import 'package:pdf_signature/data/services/export_providers.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

class _TestPdfController extends PdfController {
  _TestPdfController() : super() {
    // Start with a loaded multi-page doc, page 1 of 5
    state = PdfState.initial().copyWith(
      loaded: true,
      pageCount: 5,
      currentPage: 1,
    );
  }
}

void main() {
  testWidgets('PDF navigation: prev/next and goto update page label', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useMockViewerProvider.overrideWithValue(true),
          pdfProvider.overrideWith((ref) => _TestPdfController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const PdfSignatureHomePage(),
        ),
      ),
    );

    // Initial label and page list exists (continuous mock)
    expect(find.byKey(const Key('lbl_page_info')), findsOneWidget);
    Text label() => tester.widget<Text>(find.byKey(const Key('lbl_page_info')));
    expect(label().data, equals('Page 1/5'));
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);

    // Next
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();
    expect(label().data, equals('Page 2/5'));
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);

    // Prev
    await tester.tap(find.byKey(const Key('btn_prev')));
    await tester.pumpAndSettle();
    expect(label().data, equals('Page 1/5'));
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);

    // Goto specific page
    await tester.tap(find.byKey(const Key('txt_goto')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('txt_goto')), '4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(label().data, equals('Page 4/5'));
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);

    // Goto beyond upper bound -> clamp to 5
    await tester.tap(find.byKey(const Key('txt_goto')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('txt_goto')), '999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(label().data, equals('Page 5/5'));
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);

    // Goto below 1 -> clamp to 1
    await tester.tap(find.byKey(const Key('txt_goto')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('txt_goto')), '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(label().data, equals('Page 1/5'));
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);
  });
}
