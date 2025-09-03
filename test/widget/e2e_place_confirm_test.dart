import 'dart:ui' as ui;
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import 'package:pdf_signature/data/services/export_providers.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

void main() {
  // Open the active overlay context menu robustly (mouse right-click, fallback to long-press)
  Future<void> _openActiveMenuAndConfirm(WidgetTester tester) async {
    final overlay = find.byKey(const Key('signature_overlay'));
    expect(overlay, findsOneWidget);
    // Ensure visible before interacting
    await tester.ensureVisible(overlay);
    await tester.pumpAndSettle();

    // Try right-click first
    final center = tester.getCenter(overlay);
    final TestGesture mouse = await tester.createGesture(
      kind: ui.PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.addPointer(location: center);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.down(center);
    await tester.pump(const Duration(milliseconds: 30));
    await mouse.up();
    await tester.pumpAndSettle();

    // If menu didn't appear, try long-press
    if (find.byKey(const Key('ctx_active_confirm')).evaluate().isEmpty) {
      await tester.longPress(overlay, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('ctx_active_confirm')));
    await tester.pumpAndSettle();
  }

  // Build a simple in-memory PNG as a signature image
  Uint8List _makeSig() {
    final canvas = img.Image(width: 80, height: 40);
    img.fill(canvas, color: img.ColorUint8.rgb(255, 255, 255));
    img.drawLine(
      canvas,
      x1: 6,
      y1: 20,
      x2: 74,
      y2: 20,
      color: img.ColorUint8.rgb(0, 0, 0),
    );
    return Uint8List.fromList(img.encodePng(canvas));
  }

  testWidgets('E2E: select, place default, and confirm signature', (
    tester,
  ) async {
    final sigBytes = _makeSig();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Open a PDF
          pdfProvider.overrideWith(
            (ref) => PdfController()..openPicked(path: 'test.pdf'),
          ),
          // Provide one signature asset in the library
          signatureLibraryProvider.overrideWith((ref) {
            final c = SignatureLibraryController();
            c.add(sigBytes, name: 'image');
            return c;
          }),
          // Use mock continuous viewer for deterministic layout in widget tests
          useMockViewerProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PdfSignatureHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the signature card to set it as active overlay
    final card = find.byKey(const Key('gd_signature_card_area')).first;
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pump();

    // Active overlay should appear
    final active = find.byKey(const Key('signature_overlay'));
    expect(active, findsOneWidget);
    final sizeBefore = tester.getSize(active);

    // Bring the overlay into the viewport (it's near the bottom of the page by default)
    final listFinder = find.byKey(const Key('pdf_continuous_mock_list'));
    if (listFinder.evaluate().isNotEmpty) {
      // Ensure the active overlay is fully visible within the scrollable viewport
      await tester.ensureVisible(active);
      await tester.pumpAndSettle();
    }

    // Open context menu and confirm using a robust flow
    await _openActiveMenuAndConfirm(tester);

    // Verify active overlay gone and placed overlay shown
    expect(find.byKey(const Key('signature_overlay')), findsNothing);
    final placed = find.byKey(const Key('placed_signature_0'));
    expect(placed, findsOneWidget);
    final sizeAfter = tester.getSize(placed);

    // Compare sizes: should be roughly equal (allowing small layout variance)
    expect(
      (sizeAfter.width - sizeBefore.width).abs() < sizeBefore.width * 0.15,
      isTrue,
    );
    expect(
      (sizeAfter.height - sizeBefore.height).abs() < sizeBefore.height * 0.15,
      isTrue,
    );

    // Verify provider state reflects one placement on current page
    final ctx = tester.element(find.byType(PdfSignatureHomePage));
    final container = ProviderScope.containerOf(ctx);
    final pdf = container.read(pdfProvider);
    final list = pdf.placementsByPage[pdf.currentPage] ?? const [];
    expect(list.length, 1);
  });
}
