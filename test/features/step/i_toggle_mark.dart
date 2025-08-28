import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: I toggle mark
Future<void> iToggleMark(WidgetTester tester) async {
  final c = TestWorld.container!;
  c.read(pdfProvider.notifier).toggleMark();
}
