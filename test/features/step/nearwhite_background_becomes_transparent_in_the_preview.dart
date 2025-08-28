import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: near-white background becomes transparent in the preview
Future<void> nearwhiteBackgroundBecomesTransparentInThePreview(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(signatureProvider).bgRemoval, isTrue);
}
