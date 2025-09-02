import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the signature on page {2} remains
Future<void> theSignatureOnPageRemains(WidgetTester tester, num page) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final list = container.read(pdfProvider.notifier).placementsOn(page.toInt());
  expect(list, isNotEmpty);
}
