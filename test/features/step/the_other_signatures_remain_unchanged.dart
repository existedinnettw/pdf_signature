import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the other signatures remain unchanged
Future<void> theOtherSignaturesRemainUnchanged(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final list = container.read(pdfProvider.notifier).placementsOn(1);
  // After deleting index 1, two should remain
  expect(list.length, 2);
}
