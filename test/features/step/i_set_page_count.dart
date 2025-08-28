import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: I set page count {9}
Future<void> iSetPageCount(WidgetTester tester, int count) async {
  final c = TestWorld.container!;
  c.read(pdfProvider.notifier).setPageCount(count);
}
