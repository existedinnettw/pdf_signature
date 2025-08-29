import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: pdf page count is {7}
Future<void> pdfPageCountIs(WidgetTester tester, int expected) async {
  final c = TestWorld.container!;
  expect(c.read(pdfProvider).pageCount, expected);
}
