import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: the image is not added to the document
Future<void> theImageIsNotAddedToTheDocument(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  expect(sig.rect, isNull);
}
