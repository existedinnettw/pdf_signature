import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: that page is displayed
Future<void> thatPageIsDisplayed(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(pdfProvider).currentPage, 3);
}
