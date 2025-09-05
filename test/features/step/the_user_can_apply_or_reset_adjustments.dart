import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: the user can apply or reset adjustments
Future<void> theUserCanApplyOrResetAdjustments(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  expect(sig.contrast, isNotNull);
  expect(sig.brightness, isNotNull);
}
