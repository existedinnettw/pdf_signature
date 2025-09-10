import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: the user attempts to save
Future<void> theUserAttemptsToSave(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final pdf = container.read(documentRepositoryProvider);
  final sig = container.read(signatureProvider);
  // Simulate save attempt: since rect is null, mark flag
  if (!pdf.loaded || sig.rect == null) {
    TestWorld.nothingToSaveAttempt = true;
  }
}
