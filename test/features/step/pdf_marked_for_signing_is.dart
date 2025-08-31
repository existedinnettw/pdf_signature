import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: pdf marked for signing is {false}
Future<void> pdfMarkedForSigningIs(WidgetTester tester, bool expected) async {
  final container = TestWorld.container ?? ProviderContainer();
  final signed = container.read(pdfProvider).signedPage != null;
  expect(signed, expected);
}
