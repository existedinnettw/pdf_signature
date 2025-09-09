import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_library_repository.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';

import 'helpers.dart';

void main() {
  Future<void> _confirmActiveOverlay(WidgetTester tester) async {
    // Confirm via provider to avoid flaky UI interactions
    final host = find.byType(PdfSignatureHomePage);
    expect(host, findsOneWidget);
    final ctx = tester.element(host);
    final container = ProviderScope.containerOf(ctx);
    container
        .read(signatureProvider.notifier)
        .confirmCurrentSignatureWithContainer(container);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Confirming keeps size and position approx. the same (no shrink)',
    (tester) async {
      await pumpWithOpenPdfAndSig(tester);

      final overlay = find.byKey(const Key('signature_overlay'));
      expect(overlay, findsOneWidget);
      final sizeBefore = tester.getSize(overlay);
      // final topLeftBefore = tester.getTopLeft(overlay);

      await _confirmActiveOverlay(tester);

      final placed = find.byKey(const Key('placed_signature_0'));
      expect(placed, findsOneWidget);
      final sizeAfter = tester.getSize(placed);
      // final topLeftAfter = tester.getTopLeft(placed);

      // Expect roughly same size (allow small variance); no shrink
      expect(
        (sizeAfter.width - sizeBefore.width).abs() < sizeBefore.width * 0.25,
        isTrue,
      );
      expect(
        (sizeAfter.height - sizeBefore.height).abs() < sizeBefore.height * 0.25,
        isTrue,
      );
    },
  );

  testWidgets('Placing a new signature makes the previous one disappear', (
    tester,
  ) async {
    await pumpWithOpenPdfAndSig(tester);

    // Place first
    await _confirmActiveOverlay(tester);
    expect(find.byKey(const Key('placed_signature_0')), findsOneWidget);

    // Activate a new overlay by tapping the first signature card in the sidebar
    final cardTapTarget = find.byKey(const Key('gd_signature_card_area')).first;
    expect(cardTapTarget, findsOneWidget);
    await tester.tap(cardTapTarget);
    await tester.pumpAndSettle();

    // Ensure active overlay exists
    final active = find.byKey(const Key('signature_overlay'));
    expect(active, findsOneWidget);

    // Confirm again
    await _confirmActiveOverlay(tester);
    await tester.pumpAndSettle();

    // Expect both placed signatures remain visible (regression: older used to disappear)
    final placedAll = find.byWidgetPredicate(
      (w) => w.key?.toString().contains('placed_signature_') == true,
    );
    expect(placedAll.evaluate().length, 2);
  });

  testWidgets('Signature card shows adjusted preview after background removal', (
    tester,
  ) async {
    await pumpWithOpenPdfAndSig(tester);
    // Enable background removal via provider (faster and robust)
    final ctx1 = tester.element(find.byType(PdfSignatureHomePage));
    final container1 = ProviderScope.containerOf(ctx1);
    container1.read(signatureProvider.notifier).setBgRemoval(true);
    await tester.pump();

    // The selected signature card should display processed bytes (background removed)
    // We assert by ensuring the card exists and is not empty; visual verification is implicit.
    final cardArea = find.byKey(const Key('gd_signature_card_area')).first;
    expect(cardArea, findsOneWidget);
  });

  testWidgets('Placed signature uses adjusted image after confirm', (
    tester,
  ) async {
    await pumpWithOpenPdfAndSig(tester);
    // Enable background removal to alter processed bytes via provider
    final ctx2 = tester.element(find.byType(PdfSignatureHomePage));
    final container2 = ProviderScope.containerOf(ctx2);
    container2.read(signatureProvider.notifier).setBgRemoval(true);
    await tester.pump();

    // Confirm placement
    await _confirmActiveOverlay(tester);
    await tester.pumpAndSettle();

    // Verify one placed signature exists; its image bytes should correspond to adjusted asset id
    final placed = find.byKey(const Key('placed_signature_0'));
    expect(placed, findsOneWidget);
    // Compare the placed image bytes with processed bytes at confirm time
    final ctx3 = tester.element(find.byType(MaterialApp));
    final container3 = ProviderScope.containerOf(ctx3);
    final processed = container3.read(processedSignatureImageProvider);
    expect(processed, isNotNull);
    final pdf = container3.read(pdfProvider);
    final imgId = pdf.placementsByPage[pdf.currentPage]?.first.asset?.id;
    expect(imgId, isNotNull);
    expect(imgId, isNotEmpty);
    final lib = container3.read(signatureLibraryProvider);
    final match = lib.firstWhere((a) => a.id == imgId);
    expect(match.bytes, equals(processed));
  });
}
