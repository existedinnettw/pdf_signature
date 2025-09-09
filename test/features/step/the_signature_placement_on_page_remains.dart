import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the signature placement on page {2} remains
Future<void> theSignaturePlacementOnPageRemains(
  WidgetTester tester,
  num param1,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);
  final page = param1.toInt();
  expect(pdf.placementsByPage[page], isNotEmpty);
}
