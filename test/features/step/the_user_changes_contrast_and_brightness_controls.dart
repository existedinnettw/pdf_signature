import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import '_world.dart';

/// Usage: the user changes contrast and brightness controls
Future<void> theUserChangesContrastAndBrightnessControls(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(signatureProvider.notifier)
    ..setContrast(1.3)
    ..setBrightness(0.2);
  // Let provider updates settle
  await tester.pumpAndSettle();
}
