import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: signature image bytes is not null
Future<void> signatureImageBytesIsNotNull(WidgetTester tester) async {
  final c = TestWorld.container!;
  expect(c.read(signatureProvider).imageBytes, isNotNull);
}
