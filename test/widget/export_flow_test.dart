import 'dart:typed_data';
import 'package:file_selector/file_selector.dart' as fs;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf_signature/ui/features/pdf/view_model/pdf_export_view_model.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';

import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

void main() {
  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
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
                  ..openPicked(pageCount: 5, bytes: Uint8List(0)),
          ),
          pdfViewModelProvider.overrideWith(
            (ref) => PdfViewModel(ref, useMockViewer: true),
          ),
          pdfExportViewModelProvider.overrideWith(
            (ref) => PdfExportViewModel(
              ref,
              savePathPicker: () async => 'C:/tmp/output.pdf',
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: fs.XFile(''),
          ),
        ),
      ),
    );
    // Let async providers (SharedPreferences) resolve
    await tester.pumpAndSettle();

    // Trigger save directly (mark toggle no longer required)
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();

    // Expect success UI (localized)
    expect(find.textContaining('Saved:'), findsOneWidget);
    // Basic assertion: a save flow completed and snackbar showed
  });
}
