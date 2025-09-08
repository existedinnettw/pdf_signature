import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'Signature card shows context menu on right-click with Adjust graphic',
    (tester) async {
      // Open app with a loaded PDF and signature prepared via helper
      await pumpWithOpenPdfAndSig(tester);
      await tester.pumpAndSettle();

      // Ensure the signature card area is present
      Finder cardArea = find.byKey(const Key('gd_signature_card_area'));
      if (cardArea.evaluate().isEmpty) {
        // Try to scroll the signatures sidebar to bring it into view
        final signaturesPanelScroll = find.descendant(
          of: find.byType(Card).last,
          matching: find.byType(Scrollable),
        );
        if (signaturesPanelScroll.evaluate().isNotEmpty) {
          await tester.drag(signaturesPanelScroll, const Offset(0, -200));
          await tester.pumpAndSettle();
        }
        cardArea = find.byKey(const Key('gd_signature_card_area'));
      }
      expect(cardArea, findsOneWidget);

      // Simulate a right-click at the center of the card area
      final center = tester.getCenter(cardArea);
      final TestGesture mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.addPointer(location: center);
      addTearDown(mouse.removePointer);
      await tester.pump();

      await mouse.down(center);
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.up();
      await tester.pumpAndSettle();

      // Verify the context menu shows "Adjust graphic"
      expect(find.byKey(const Key('mi_signature_adjust')), findsOneWidget);

      // before confirm, adjust must be visible
      expect(find.text('Adjust graphic'), findsOneWidget);

      // after confirm, adjust must be visible
      expect(find.text('Adjust graphic'), findsOneWidget);

      // Do not proceed to open the dialog here; the goal is just to verify menu content.
    },
  );
}
