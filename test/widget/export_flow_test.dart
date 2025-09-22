import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

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

// A fake export VM that always reports success, so this widget test doesn't
// depend on PDF validity or platform specifics.
bool exported = false;

class _FakePdfExportViewModel extends PdfExportViewModel {
  _FakePdfExportViewModel(Ref ref)
    : super(ref, savePathPicker: () async => 'C:/tmp/output.pdf');

  @override
  Future<bool> exportToPath({
    required String outputPath,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    double targetDpi = 144.0,
  }) async {
    exported = true;
    return true;
  }
}

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
            (ref) => _FakePdfExportViewModel(ref),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PdfSignatureHomePage(
            onPickPdf: () async {},
            onClosePdf: () {},
            currentFile: XFile(''),
          ),
        ),
      ),
    );
    // Let async providers (SharedPreferences) resolve
    await tester.pumpAndSettle();

    // Trigger save directly (mark toggle no longer required)
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    // Pump a bit to allow async export flow to run.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    // Basic assertion: export was invoked
    expect(exported, isTrue);
  });
}
