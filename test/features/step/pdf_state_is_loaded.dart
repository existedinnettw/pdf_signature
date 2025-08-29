import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: pdf state is loaded {true}
Future<void> pdfStateIsLoaded(WidgetTester tester, bool expected) async {
  final c = TestWorld.container!;
  expect(c.read(pdfProvider).loaded, expected);
}
