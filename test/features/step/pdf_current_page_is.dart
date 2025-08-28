import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: pdf current page is {1}
Future<void> pdfCurrentPageIs(WidgetTester tester, int expected) async {
  final c = TestWorld.container!;
  expect(c.read(pdfProvider).currentPage, expected);
}
