import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_signature/signature.dart' as hand;

import 'package:pdf_signature/ui/features/pdf/widgets/draw_canvas.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

void main() {
  testWidgets('DrawCanvas exports non-empty bytes on confirm', (tester) async {
    Uint8List? exported;
    final sink = ValueNotifier<Uint8List?>(null);
    final control = hand.HandSignatureControl();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('DrawCanvas calls onConfirm with bytes when confirm is pressed', (
    tester,
  ) async {
    Uint8List? confirmedBytes;
    final sink = ValueNotifier<Uint8List?>(null);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DrawCanvas(
            debugBytesSink: sink,
            onConfirm: (bytes) {
              confirmedBytes = bytes;
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
    // Wait until bytes are available
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final end = DateTime.now().add(const Duration(seconds: 2));
      while ((confirmedBytes == null && sink.value == null) &&
          DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    confirmedBytes ??= sink.value;

    // Verify that onConfirm was called with non-empty bytes
    expect(confirmedBytes, isNotNull);
    expect(confirmedBytes!.isNotEmpty, isTrue);
  });
}
