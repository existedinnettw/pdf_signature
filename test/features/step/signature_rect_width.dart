import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: signature rect width > {50}
Future<void> signatureRectWidth(WidgetTester tester, num minWidth) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.width, greaterThan(minWidth.toDouble()));
}
