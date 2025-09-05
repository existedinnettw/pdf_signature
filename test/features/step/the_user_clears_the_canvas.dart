import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: the user clears the canvas
Future<void> theUserClearsTheCanvas(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(signatureProvider.notifier).setStrokes([]);
}
