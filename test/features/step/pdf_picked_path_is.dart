import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: pdf picked path is {'test.pdf'}
Future<void> pdfPickedPathIs(WidgetTester tester, String expected) async {
  final c = TestWorld.container!;
  final s = c.read(pdfProvider);
  expect(s.pickedPdfPath, expected);
}
