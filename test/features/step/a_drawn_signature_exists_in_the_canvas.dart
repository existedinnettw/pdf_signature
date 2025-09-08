import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: a drawn signature exists in the canvas
Future<void> aDrawnSignatureExistsInTheCanvas(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sigN = container.read(signatureProvider.notifier);
  sigN.setStrokes([
    [const Offset(0, 0), const Offset(1, 1)],
  ]);
}
