import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_controller.dart';
import '_world.dart';

/// Usage: the user clicks the thumbnail for page {2}
Future<void> theUserClicksTheThumbnailForPage(
  WidgetTester tester,
  num param1,
) async {
  final page = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  c.read(pdfProvider.notifier).jumpTo(page);
  await tester.pump();
}
