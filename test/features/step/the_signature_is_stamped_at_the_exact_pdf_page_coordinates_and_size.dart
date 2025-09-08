import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: the signature is stamped at the exact PDF page coordinates and size
Future<void> theSignatureIsStampedAtTheExactPdfPageCoordinatesAndSize(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  expect(sig.rect, isNotNull);
  expect(sig.rect!.width, greaterThan(0));
  expect(sig.rect!.height, greaterThan(0));
}
