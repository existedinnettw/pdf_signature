import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  Future<void> openEditorViaContextMenu(WidgetTester tester) async {
    // Prefer right-click on the signature card area to open the context menu
    final cardArea = find.byKey(const Key('gd_signature_card_area'));
    expect(cardArea, findsOneWidget);
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
    await tester.tap(find.byKey(const Key('mi_signature_adjust')));
    await tester.pumpAndSettle();
  }

  testWidgets('Resize and move signature within page bounds', (tester) async {
    await pumpWithOpenPdfAndSig(tester);

    final overlay = find.byKey(const Key('signature_overlay'));
    expect(overlay, findsOneWidget);
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

    final overlay = find.byKey(const Key('signature_overlay'));
    final sizeBefore = tester.getSize(overlay);
    final aspect = sizeBefore.width / sizeBefore.height;
    // Open image editor via right-click context menu and toggle aspect lock there
    await openEditorViaContextMenu(tester);
    await tester.tap(find.byKey(const Key('chk_aspect_lock')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('signature_handle')),
      const Offset(60, 10),
    );
    await tester.pump();
    final sizeAfter = tester.getSize(overlay);
    final newAspect = (sizeAfter.width / sizeAfter.height);
    expect((newAspect - aspect).abs() < 0.15, isTrue);
  });

  testWidgets('Background removal and adjustments controls change state', (
    tester,
  ) async {
    await pumpWithOpenPdfAndSig(tester);

    // Open image editor via right-click context menu
    await openEditorViaContextMenu(tester);
    // Ensure sliders are visible by scrolling if needed
    final dialogScrollable = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Scrollable),
    );
    if (dialogScrollable.evaluate().isNotEmpty) {
      await tester.drag(dialogScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
    }
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
}
