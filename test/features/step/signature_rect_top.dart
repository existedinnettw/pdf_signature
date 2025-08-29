import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature rect top >= {0}
Future<void> signatureRectTop(WidgetTester tester, num minTop) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.top, greaterThanOrEqualTo(minTop.toDouble()));
}
