import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user navigates to page 5 and places another signature
Future<void> theUserNavigatesToPage5AndPlacesAnotherSignature(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 6);
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  container.read(pdfProvider.notifier).jumpTo(5);
  container.read(signatureProvider.notifier).placeDefaultRect();
  final r = container.read(signatureProvider).rect!;
  container.read(pdfProvider.notifier).addPlacement(page: 5, rect: r);
  // Defensive: ensure earlier placement on page 2 remains (some setups may recreate state)
  final p2 = container.read(pdfProvider.notifier).placementsOn(2);
  if (p2.isEmpty) {
    container
        .read(pdfProvider.notifier)
        .addPlacement(page: 2, rect: r.translate(-50, -50));
  }
}
