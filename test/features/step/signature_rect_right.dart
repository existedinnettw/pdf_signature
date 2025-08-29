import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature rect right <= {400}
Future<void> signatureRectRight(WidgetTester tester, num maxRight) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.right, lessThanOrEqualTo(maxRight.toDouble()));
}
