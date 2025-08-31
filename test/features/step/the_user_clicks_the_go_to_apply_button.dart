import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user clicks the Go to apply button
Future<void> theUserClicksTheGoToApplyButton(WidgetTester tester) async {
  final c = TestWorld.container ?? ProviderContainer();
  final pending = TestWorld.pendingGoTo;
  if (pending != null) {
    c.read(pdfProvider.notifier).jumpTo(pending);
    await tester.pump();
  }
}
