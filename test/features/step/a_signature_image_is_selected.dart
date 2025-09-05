import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: a signature image is selected
Future<void> aSignatureImageIsSelected(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 2);
  container.read(pdfProvider.notifier).setSignedPage(1);
  container
      .read(signatureProvider.notifier)
      .setImageBytes(Uint8List.fromList([1, 2, 3]));
  // Allow provider scheduler to process queued updates fully
  await tester.pumpAndSettle();
  // Extra pump with a non-zero duration to flush zero-delay timers
  await tester.pump(const Duration(milliseconds: 1));
  // Teardown to avoid pending timers from Riverpod's scheduler
  addTearDown(() {
    TestWorld.container?.dispose();
    TestWorld.container = null;
  });
}
