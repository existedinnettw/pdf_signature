import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: near-white background becomes transparent in the preview
Future<void> nearwhiteBackgroundBecomesTransparentInThePreview(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  // Ensure the flag is on per the previous step
  expect(container.read(signatureProvider).bgRemoval, isTrue);

  // Build a tiny 2x1 image: left pixel near-white (should become transparent),
  // right pixel black (should remain opaque).
  final src = img.Image(width: 2, height: 1);
  // Near-white >= thrHigh(245) to ensure fully transparent after processing
  src.setPixelRgba(0, 0, 250, 250, 250, 255);
  // Solid black stays opaque
  src.setPixelRgba(1, 0, 0, 0, 0, 255);
  final png = Uint8List.fromList(img.encodePng(src, level: 6));

  // Feed this into signature state
  container.read(signatureProvider.notifier).setImageBytes(png);
  // Allow provider scheduler to process invalidations
  await tester.pumpAndSettle();
  // Get processed bytes
  final processed = container.read(processedSignatureImageProvider);
  expect(processed, isNotNull);
  final decoded = img.decodeImage(processed!);
  expect(decoded, isNotNull);
  final outImg = decoded!.hasAlpha ? decoded : decoded.convert(numChannels: 4);

  final p0 = outImg.getPixel(0, 0);
  final p1 = outImg.getPixel(1, 0);
  final a0 = (p0.aNormalized * 255).round();
  final a1 = (p1.aNormalized * 255).round();
  expect(a0, equals(0), reason: 'near-white should be transparent');
  expect(a1, equals(255), reason: 'dark pixel should remain opaque');
}
