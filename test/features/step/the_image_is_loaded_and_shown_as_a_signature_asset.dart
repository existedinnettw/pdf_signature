import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the image is loaded and shown as a signature asset
Future<void> theImageIsLoadedAndShownAsASignatureAsset(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  expect(sig.imageBytes, isNotNull);
  expect(sig.rect, isNotNull);
}
