import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: a signature is placed with a position and size relative to the page
Future<void> aSignatureIsPlacedWithAPositionAndSizeRelativeToThePage(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(
        path: 'mock.pdf',
        pageCount: 2,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
  container.read(pdfProvider.notifier).setSignedPage(1);
  final r = Rect.fromLTWH(50, 100, 120, 60);
  final sigN = container.read(signatureProvider.notifier);
  sigN.placeDefaultRect();
  // overwrite to desired rect
  final sig = container.read(signatureProvider);
  sigN
    ..toggleAspect(true)
    ..resize(Offset(r.width - sig.rect!.width, r.height - sig.rect!.height));
  // move to target top-left
  final movedDelta = Offset(r.left - sig.rect!.left, r.top - sig.rect!.top);
  sigN.drag(movedDelta);
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([4, 5, 6]));
}
