import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user deletes one selected signature
Future<void> theUserDeletesOneSelectedSignature(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  // Remove the middle one (index 1)
  container.read(pdfProvider.notifier).removePlacement(page: 1, index: 1);
}
