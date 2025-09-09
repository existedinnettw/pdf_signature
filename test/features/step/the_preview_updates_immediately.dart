import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import '_world.dart';

/// Usage: the preview updates immediately
Future<void> thePreviewUpdatesImmediately(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  expect(sig.contrast, closeTo(1.3, 1e-6));
  expect(sig.brightness, closeTo(0.2, 1e-6));
}
