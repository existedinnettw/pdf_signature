import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user places a signature on page 1
Future<void> theUserPlacesASignatureOnPage1(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Ensure image exists so placement is meaningful
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  // Place a default rect on page 1
  container.read(signatureProvider.notifier).placeDefaultRect();
  final rect = container.read(signatureProvider).rect!;
  container.read(pdfProvider.notifier).addPlacement(page: 1, rect: rect);
}
