import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the image scales proportionally
Future<void> theImageScalesProportionally(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  final aspect = sig.rect!.width / sig.rect!.height;
  expect((aspect - (TestWorld.prevAspect ?? aspect)).abs() < 0.05, isTrue);
}
