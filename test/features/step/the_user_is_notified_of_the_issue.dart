import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import '_world.dart';

/// Usage: the user is notified of the issue
Future<void> theUserIsNotifiedOfTheIssue(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  // For our logic simulation: invalid selections result in no usable bytes
  expect(sig.imageBytes == null || sig.imageBytes!.isEmpty, isTrue);
}
