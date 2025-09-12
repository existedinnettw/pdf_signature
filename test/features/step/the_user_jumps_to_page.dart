import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user jumps to page {2}
Future<void> theUserJumpsToPage(WidgetTester tester, num param1) async {
  final page = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  try {
    c.read(pdfViewModelProvider).jumpToPage(page);
  } catch (_) {}
  await tester.pump();
}
