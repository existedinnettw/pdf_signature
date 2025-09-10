import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/data/services/export_service.dart';
import 'package:pdf_signature/data/services/export_providers.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

class RecordingExporter extends ExportService {
  bool called = false;
  @override
  Future<bool> saveBytesToFile({required bytes, required outputPath}) async {
    called = true;
    return true;
  }
}

void main() {
  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
    final fake = RecordingExporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWith(
            (ref) => DocumentStateNotifier()..openPicked(path: 'test.pdf'),
          ),
          signatureProvider.overrideWith(
            (ref) => SignatureController()..placeDefaultRect(),
          ),
          useMockViewerProvider.overrideWith((ref) => true),
          exportServiceProvider.overrideWith((_) => fake),
          savePathPickerProvider.overrideWith(
            (_) => () async => 'C:/tmp/output.pdf',
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PdfSignatureHomePage(),
        ),
      ),
    );
    await tester.pump();

    // Trigger save directly (mark toggle no longer required)
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();

    // Expect success UI
    expect(find.textContaining('Saved:'), findsOneWidget);
  });
}
