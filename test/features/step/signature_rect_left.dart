import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature rect left >= {0}
Future<void> signatureRectLeft(WidgetTester tester, num minLeft) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.left, greaterThanOrEqualTo(minLeft.toDouble()));
}
