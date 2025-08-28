import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: pdf marked for signing is {false}
Future<void> pdfMarkedForSigningIs(WidgetTester tester, bool expected) async {
  final c = TestWorld.container!;
  expect(c.read(pdfProvider).markedForSigning, expected);
}
