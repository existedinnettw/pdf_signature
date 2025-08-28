import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: I openPicked with path {'test.pdf'} and pageCount {7}
Future<void> iOpenpickedWithPathAndPagecount(
  WidgetTester tester,
  String path,
  int pageCount,
) async {
  final c = TestWorld.container!;
  c.read(pdfProvider.notifier).openPicked(path: path, pageCount: pageCount);
}
