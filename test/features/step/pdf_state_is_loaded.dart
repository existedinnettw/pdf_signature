import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: pdf state is loaded {true}
Future<void> pdfStateIsLoaded(WidgetTester tester, bool expected) async {
  final c = TestWorld.container!;
  expect(c.read(pdfProvider).loaded, expected);
}
