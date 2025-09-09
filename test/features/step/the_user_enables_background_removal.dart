import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import '_world.dart';

/// Usage: the user enables background removal
Future<void> theUserEnablesBackgroundRemoval(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(signatureProvider.notifier).setBgRemoval(true);
  // Let provider updates settle
  await tester.pumpAndSettle();
}
