import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user navigates to page 3 and places another signature
Future<void> theUserNavigatesToPage3AndPlacesAnotherSignature(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(pdfProvider.notifier).jumpTo(3);
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  container.read(signatureProvider.notifier).placeDefaultRect();
  final rect = container.read(signatureProvider).rect!;
  container.read(pdfProvider.notifier).addPlacement(page: 3, rect: rect);
}
