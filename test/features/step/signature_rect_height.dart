import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: signature rect height > {20}
Future<void> signatureRectHeight(WidgetTester tester, num minHeight) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.height, greaterThan(minHeight.toDouble()));
}
