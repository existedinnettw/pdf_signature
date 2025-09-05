import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user selects "<file>"
Future<void> theUserSelects(WidgetTester tester, dynamic file) async {
  // New isolated container per outline example
  TestWorld.reset();
  final container = ProviderContainer();
  TestWorld.container = container;
  // Mark page for signing to enable signature ops
  container
      .read(pdfProvider.notifier)
      .openPicked(path: 'mock.pdf', pageCount: 1);
  container.read(pdfProvider.notifier).setSignedPage(1);
  // For invalid/unsupported/empty selections we do NOT set image bytes.
  // This simulates a failed load and keeps rect null.
  final token = file.toString();
  if (token.isNotEmpty) {
    // intentionally no-op for corrupted/signature.bmp/empty.jpg
  }
}
