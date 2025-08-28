import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
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
