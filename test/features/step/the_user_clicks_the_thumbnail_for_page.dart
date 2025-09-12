import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user clicks the thumbnail for page {2}
Future<void> theUserClicksTheThumbnailForPage(
  WidgetTester tester,
  num param1,
) async {
  final page = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  try {
    c.read(currentPageProvider.notifier).state = page;
  } catch (_) {}
  try {
    c.read(pdfViewModelProvider.notifier).jumpToPage(page);
  } catch (_) {}
  await tester.pump();
}
