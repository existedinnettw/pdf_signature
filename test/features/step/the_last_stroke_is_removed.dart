import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: the last stroke is removed
Future<void> theLastStrokeIsRemoved(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  expect(sig.strokes.length, 1);
}
