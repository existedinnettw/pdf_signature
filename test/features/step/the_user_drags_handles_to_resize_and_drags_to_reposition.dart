import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: the user drags handles to resize and drags to reposition
Future<void> theUserDragsHandlesToResizeAndDragsToReposition(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sigN = container.read(signatureProvider.notifier);
  final sig = container.read(signatureProvider);
  TestWorld.prevCenter = sig.rect?.center;
  sigN.resize(const Offset(50, 30));
  sigN.drag(const Offset(20, -10));
}
