import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: multiple strokes were drawn
Future<void> multipleStrokesWereDrawn(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(signatureProvider.notifier).setStrokes([
    [const Offset(0, 0), const Offset(1, 1)],
    [const Offset(2, 2), const Offset(3, 3)],
  ]);
}
