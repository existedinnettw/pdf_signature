import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import '_world.dart';

/// Usage: the canvas becomes blank
Future<void> theCanvasBecomesBlank(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(signatureProvider).strokes, isEmpty);
}
