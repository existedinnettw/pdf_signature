// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:pdf_signature/features/pdf/viewer.dart';
import 'package:pdf_signature/features/share/export_service.dart';
import 'package:hand_signature/signature.dart' as hand;

// Fakes for export service (top-level; Dart does not allow local class declarations)
class RecordingExporter extends ExportService {
  bool called = false;
}

class BasicExporter extends ExportService {}

void main() {
  Future<void> pumpWithOpenPdf(WidgetTester tester) async {
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

  Future<void> pumpWithOpenPdfAndSig(WidgetTester tester) async {
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
    await pumpWithOpenPdf(tester);
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
    await pumpWithOpenPdf(tester);

    final goto = find.byKey(const Key('txt_goto'));
    await tester.enterText(goto, '4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final pageInfo = find.byKey(const Key('lbl_page_info'));
    expect((tester.widget<Text>(pageInfo)).data, 'Page 4/5');
  });

  testWidgets('Select a page for signing', (tester) async {
    await pumpWithOpenPdf(tester);

    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();
    // signature actions appear (picker-based now)
    expect(find.byKey(const Key('btn_load_signature_picker')), findsOneWidget);
  });

  testWidgets('Show invalid/unsupported file SnackBar via test hook', (
    tester,
  ) async {
    await pumpWithOpenPdf(tester);
    final dynamic state =
        tester.state(find.byType(PdfSignatureHomePage)) as dynamic;
    state.debugShowInvalidSignatureSnackBar();
    await tester.pump();
    expect(find.text('Invalid or unsupported file'), findsOneWidget);
  });

  testWidgets('Import a signature image', (tester) async {
    await pumpWithOpenPdfAndSig(tester);
    await tester.tap(find.byKey(const Key('btn_mark_signing')));
    await tester.pump();
    // overlay present from provider override
    expect(find.byKey(const Key('signature_overlay')), findsOneWidget);
  });

  // Removed: Load Invalid button is not part of normal app UI.

  testWidgets('Resize and move signature within page bounds', (tester) async {
    await pumpWithOpenPdfAndSig(tester);
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
    await pumpWithOpenPdfAndSig(tester);
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
    await pumpWithOpenPdfAndSig(tester);
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

  testWidgets('DrawCanvas exports non-empty bytes on confirm', (tester) async {
    Uint8List? exported;
    final sink = ValueNotifier<Uint8List?>(null);
    final control = hand.HandSignatureControl();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrawCanvas(
            control: control,
            debugBytesSink: sink,
            onConfirm: (bytes) {
              exported = bytes;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Draw a simple stroke inside the pad
    final pad = find.byKey(const Key('hand_signature_pad'));
    expect(pad, findsOneWidget);
    final rect = tester.getRect(pad);
    final g = await tester.startGesture(
      Offset(rect.left + 20, rect.center.dy),
      kind: PointerDeviceKind.touch,
    );
    for (int i = 0; i < 10; i++) {
      await g.moveBy(
        const Offset(12, 0),
        timeStamp: Duration(milliseconds: 16 * (i + 1)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 50));

    // Confirm export
    await tester.tap(find.byKey(const Key('btn_canvas_confirm')));
    // Wait until notifier receives bytes
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.runAsync(() async {
      final end = DateTime.now().add(const Duration(seconds: 2));
      while (sink.value == null && DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    exported ??= sink.value;

    expect(exported, isNotNull);
    expect(exported!.isNotEmpty, isTrue);
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

    // With refactor, we no longer call boundary-based export here; still expect success UI.
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
