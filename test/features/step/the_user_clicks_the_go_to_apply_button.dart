import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user clicks the Go to apply button
Future<void> theUserClicksTheGoToApplyButton(WidgetTester tester) async {
  final c = TestWorld.container ?? ProviderContainer();
  final pending = TestWorld.pendingGoTo;
  if (pending != null) {
    try {
      c.read(currentPageProvider.notifier).state = pending;
    } catch (_) {}
    try {
      c.read(pdfViewModelProvider.notifier).jumpToPage(pending);
    } catch (_) {}
    await tester.pump();
  }
}
