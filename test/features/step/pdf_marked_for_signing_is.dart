import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: pdf marked for signing is {false}
Future<void> pdfMarkedForSigningIs(WidgetTester tester, bool expected) async {
  final c = TestWorld.container!;
  expect(c.read(pdfProvider).markedForSigning, expected);
}
