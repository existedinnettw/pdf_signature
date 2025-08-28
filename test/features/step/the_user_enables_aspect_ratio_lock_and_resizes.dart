import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: the user enables aspect ratio lock and resizes
Future<void> theUserEnablesAspectRatioLockAndResizes(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sigN = container.read(signatureProvider.notifier);
  final sig = container.read(signatureProvider);
  TestWorld.prevAspect = sig.rect!.width / sig.rect!.height;
  sigN.toggleAspect(true);
  sigN.resize(const Offset(100, 50));
}
