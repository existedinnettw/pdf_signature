import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf_signature/data/services/export_service.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/ui_services.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';

import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

class RecordingExporter extends ExportService {
  bool called = false;
  @override
  Future<Uint8List?> exportSignedPdfFromBytes({
    required Uint8List srcBytes,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<dynamic>>? placementsByPage,
    Map<String, Uint8List>? libraryBytes,
    double targetDpi = 144.0,
  }) async {
    // Return tiny dummy PDF bytes
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // "%PDF" header start
  }

  @override
  Future<bool> saveBytesToFile({
    required bytes,
    required String outputPath,
  }) async {
    called = true;
    return true;
  }
}

void main() {
  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = RecordingExporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          preferencesRepositoryProvider.overrideWith(
            (ref) => PreferencesStateNotifier(prefs),
          ),
          documentRepositoryProvider.overrideWith(
            (ref) =>
                DocumentStateNotifier()..openPicked(
                  path: 'test.pdf',
                  pageCount: 5,
                  bytes: Uint8List(0),
                ),
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
          home: const PdfSignatureHomePage(),
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
    expect(fake.called, isTrue);
  });
}
