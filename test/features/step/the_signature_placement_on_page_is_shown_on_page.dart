import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the signature placement on page {5} is shown on page {5}
Future<void> theSignaturePlacementOnPageIsShownOnPage(
  WidgetTester tester,
  num param1,
  num param2,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(pdfProvider);
  final page = param1.toInt();
  expect(pdf.placementsByPage[page], isNotEmpty);
}
