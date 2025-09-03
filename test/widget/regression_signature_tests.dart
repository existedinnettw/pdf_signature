import 'dart:ui' as ui;
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  Future<void> _confirmActiveOverlay(WidgetTester tester) async {
    final overlay = find.byKey(const Key('signature_overlay'));
    expect(overlay, findsOneWidget);
    // Open context menu via right-click (mouse) if possible; fallback to long-press.
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
      await tester.longPress(overlay);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('ctx_active_confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('Confirming causes placed signature to shrink to upper-left', (
    tester,
  ) async {
    await pumpWithOpenPdfAndSig(tester);

    final overlay = find.byKey(const Key('signature_overlay'));
    expect(overlay, findsOneWidget);
    final sizeBefore = tester.getSize(overlay);
    final topLeftBefore = tester.getTopLeft(overlay);

    await _confirmActiveOverlay(tester);

    final placed = find.byKey(const Key('placed_signature_0'));
    expect(placed, findsOneWidget);
    final sizeAfter = tester.getSize(placed);
    final topLeftAfter = tester.getTopLeft(placed);

    // Expect it appears near the page's upper-left and significantly smaller
    expect(topLeftAfter.dx <= topLeftBefore.dx + 10, isTrue);
    expect(topLeftAfter.dy <= topLeftBefore.dy + 10, isTrue);
    expect(sizeAfter.width < sizeBefore.width * 0.5, isTrue);
    expect(sizeAfter.height < sizeBefore.height * 0.5, isTrue);
  });

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

    // Optionally move a bit to avoid exact overlap
    final active = find.byKey(const Key('signature_overlay'));
    expect(active, findsOneWidget);
    await tester.drag(active, const Offset(20, 10));
    await tester.pump();

    // Confirm again
    await _confirmActiveOverlay(tester);
    await tester.pumpAndSettle();

    // Expect only one placed signature remains visible (old one disappeared)
    final placedAll = find.byWidgetPredicate(
      (w) => w.key?.toString().contains('placed_signature_') == true,
    );
    expect(placedAll.evaluate().length, 1);
  });
}
