import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_signature/app.dart';
import 'package:pdf_signature/data/repositories/preferences_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_export_view_model.dart';
import 'package:pdf_signature/data/services/export_service.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:image/image.dart' as img;

class FakeExportService extends ExportService {
  bool exported = false;
  @override
  Future<Uint8List?> exportSignedPdfFromBytes({
    Map<String, img.Image>? libraryImages,
    required Uint8List srcBytes,
    required Size uiPageSize,
    required Uint8List? signatureImageBytes,
    Map<int, List<SignaturePlacement>>? placementsByPage,
    double targetDpi = 144.0,
  }) async => Uint8List.fromList([1, 2, 3]);

  @override
  Future<bool> saveBytesToFile({
    required Uint8List bytes,
    required String outputPath,
  }) async {
    exported = true;
    return true;
  }
}

class _TestDocumentStateNotifier extends DocumentStateNotifier {
  @override
  Document build() {
    // Initialize with sample document for tests, bypassing the parent build
    return Document.initial().copyWith(
      loaded: true,
      pageCount: 5,
      pickedPdfBytes: null,
      placementsByPage: <int, List<SignaturePlacement>>{},
    );
  }
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      preferencesRepositoryProvider.overrideWith(() {
        final notifier = PreferencesStateNotifier();
        notifier.initWithPrefs(prefs);
        return notifier;
      }),
      documentRepositoryProvider.overrideWith(
        () => _TestDocumentStateNotifier(),
      ),
      pdfViewModelProvider.overrideWith(() => PdfViewModel()),
      pdfExportViewModelProvider.overrideWith(() => PdfExportViewModel()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}
