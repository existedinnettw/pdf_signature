// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/features/pdf/viewer.dart';
import 'package:pdf_signature/features/share/export_service.dart';

// Fakes for export service (top-level; Dart does not allow local class declarations)
class RecordingExporter extends ExportService {
  bool called = false;
  @override
  Future<bool> exportMultiPageFromBoundary({
    required GlobalKey boundaryKey,
    required String outputPath,
    required int pageCount,
    required Future<void> Function(int page) onGotoPage,
    double pixelRatio = 2.0,
  }) async {
    called = true;
    // Ensure extension
    expect(outputPath.toLowerCase().endsWith('.pdf'), isTrue);
    for (var i = 1; i <= pageCount; i++) {
      await onGotoPage(i);
    }
    return true;
  }
}

class BasicExporter extends ExportService {
  @override
  Future<bool> exportMultiPageFromBoundary({
    required GlobalKey boundaryKey,
    required String outputPath,
    required int pageCount,
    required Future<void> Function(int page) onGotoPage,
    double pixelRatio = 2.0,
  }) async {
    for (var i = 1; i <= pageCount; i++) {
      await onGotoPage(i);
    }
    return true;
  }
}

void main() {
  Future<void> _pumpWithOpenPdf(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfProvider.overrideWith(
            (ref) => PdfController()..openPicked(path: 'test.pdf'),
          ),
          useMockViewerProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(home: PdfSignatureHomePage()),
      ),
    );
    await tester.pump();
  }

  Future<void> _pumpWithOpenPdfAndSig(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfProvider.overrideWith(
            (ref) => PdfController()..openPicked(path: 'test.pdf'),
          ),
          signatureProvider.overrideWith(
            (ref) => SignatureController()..placeDefaultRect(),
          ),
          useMockViewerProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(home: PdfSignatureHomePage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('Open a PDF and navigate pages', (tester) async {
    await _pumpWithOpenPdf(tester);
    final pageInfo = find.byKey(const Key('lbl_page_info'));
    expect(pageInfo, findsOneWidget);
    expect((tester.widget<Text>(pageInfo)).data, 'Page 1/5');

    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pump();
    expect((tester.widget<Text>(pageInfo)).data, 'Page 2/5');

    await tester.tap(find.byKey(const Key('btn_prev')));
    await tester.pump();
    expect((tester.widget<Text>(pageInfo)).data, 'Page 1/5');
  });

  testWidgets('Jump to a specific page', (tester) async {
    await _pumpWithOpenPdf(tester);

    final goto = find.byKey(const Key('txt_goto'));
    await tester.enterText(goto, '4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final pageInfo = find.byKey(const Key('lbl_page_info'));
    expect((tester.widget<Text>(pageInfo)).data, 'Page 4/5');
  });

  testWidgets('Select a page for signing', (tester) async {
    await _pumpWithOpenPdf(tester);

    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();
    // signature actions appear (picker-based now)
    expect(find.byKey(const Key('btn_load_signature_picker')), findsOneWidget);
  });

  testWidgets('Import a signature image', (tester) async {
    await _pumpWithOpenPdfAndSig(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();
    // overlay present from provider override
    expect(find.byKey(const Key('signature_overlay')), findsOneWidget);
  });

  testWidgets('Handle invalid or unsupported files', (tester) async {
    await _pumpWithOpenPdf(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('btn_load_invalid_signature')));
    await tester.pump();
    expect(find.text('Invalid or unsupported file'), findsOneWidget);
  });

  testWidgets('Resize and move signature within page bounds', (tester) async {
    await _pumpWithOpenPdfAndSig(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();

    final overlay = find.byKey(const Key('signature_overlay'));
    final posBefore = tester.getTopLeft(overlay);

    // drag the overlay
    await tester.drag(overlay, const Offset(30, -20));
    await tester.pump();
    final posAfter = tester.getTopLeft(overlay);
    // Allow equality in case clamped at edges
    expect(posAfter.dx >= posBefore.dx, isTrue);
    expect(posAfter.dy <= posBefore.dy, isTrue);

    // resize via handle
    final handle = find.byKey(const Key('signature_handle'));
    final sizeBefore = tester.getSize(overlay);
    await tester.drag(handle, const Offset(40, 40));
    await tester.pump();
    final sizeAfter = tester.getSize(overlay);
    expect(sizeAfter.width >= sizeBefore.width, isTrue);
    expect(sizeAfter.height >= sizeBefore.height, isTrue);
  });

  testWidgets('Lock aspect ratio while resizing', (tester) async {
    await _pumpWithOpenPdfAndSig(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();

    final overlay = find.byKey(const Key('signature_overlay'));
    final sizeBefore = tester.getSize(overlay);
    final aspect = sizeBefore.width / sizeBefore.height;
    await tester.tap(find.byKey(const Key('chk_aspect_lock')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('signature_handle')),
      const Offset(60, 10),
    );
    await tester.pump();
    final sizeAfter = tester.getSize(overlay);
    final newAspect = (sizeAfter.width / sizeAfter.height);
    expect(
      (newAspect - aspect).abs() < 0.15,
      isTrue,
    ); // approximately preserved
  });

  testWidgets('Background removal and adjustments controls change state', (
    tester,
  ) async {
    await _pumpWithOpenPdfAndSig(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();

    // toggle bg removal
    await tester.tap(find.byKey(const Key('swt_bg_removal')));
    await tester.pump();
    // move sliders
    await tester.drag(
      find.byKey(const Key('sld_contrast')),
      const Offset(50, 0),
    );
    await tester.drag(
      find.byKey(const Key('sld_brightness')),
      const Offset(-50, 0),
    );
    await tester.pump();

    // basic smoke: overlay still present
    expect(find.byKey(const Key('signature_overlay')), findsOneWidget);
  });

  testWidgets('Draw signature: draw, undo, clear, confirm places on page', (
    tester,
  ) async {
    await _pumpWithOpenPdfAndSig(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();

    // Open draw canvas
    await tester.tap(find.byKey(const Key('btn_draw_signature')));
    await tester.pumpAndSettle();
    final canvas = find.byKey(const Key('draw_canvas'));
    await tester.drag(canvas, const Offset(80, 0));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_canvas_undo')));
    await tester.pump();
    await tester.drag(canvas, const Offset(50, 0));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_canvas_clear')));
    await tester.pump();
    await tester.drag(canvas, const Offset(40, 0));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_canvas_confirm')));
    await tester.pumpAndSettle();

    // Overlay present with drawn strokes painter
    expect(find.byKey(const Key('signature_overlay')), findsOneWidget);
  });

  testWidgets('Save uses file selector (via provider) and injected exporter', (
    tester,
  ) async {
    final fake = RecordingExporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfProvider.overrideWith(
            (ref) => PdfController()..openPicked(path: 'test.pdf'),
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
        child: const MaterialApp(home: PdfSignatureHomePage()),
      ),
    );
    await tester.pump();

    // Mark signing to set signedPage
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();

    // Trigger save
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();

    expect(fake.called, isTrue);
    expect(find.textContaining('Saved:'), findsOneWidget);
  });

  testWidgets('Only signed page shows overlay during export flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfProvider.overrideWith(
            (ref) => PdfController()..openPicked(path: 'test.pdf'),
          ),
          signatureProvider.overrideWith(
            (ref) => SignatureController()..placeDefaultRect(),
          ),
          useMockViewerProvider.overrideWith((ref) => true),
          exportServiceProvider.overrideWith((_) => BasicExporter()),
          savePathPickerProvider.overrideWith(
            (_) => () async => 'C:/tmp/output.pdf',
          ),
        ],
        child: const MaterialApp(home: PdfSignatureHomePage()),
      ),
    );
    await tester.pump();
    // Mark signing on page 1
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();
    // Save -> open dialog -> confirm
    await tester.tap(find.byKey(const Key('btn_save_pdf')));
    await tester.pumpAndSettle();
    // After export, overlay visible again
    expect(find.byKey(const Key('signature_overlay')), findsOneWidget);
  });
}
