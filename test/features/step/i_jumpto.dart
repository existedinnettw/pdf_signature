import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: I jumpTo {10}
Future<void> iJumpto(WidgetTester tester, int page) async {
  final c = TestWorld.container!;
  c.read(pdfProvider.notifier).jumpTo(page);
}
