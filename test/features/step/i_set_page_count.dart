import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: I set page count {9}
Future<void> iSetPageCount(WidgetTester tester, int count) async {
  final c = TestWorld.container!;
  c.read(pdfProvider.notifier).setPageCount(count);
}
