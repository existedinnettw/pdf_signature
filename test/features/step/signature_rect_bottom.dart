import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature rect bottom <= {560}
Future<void> signatureRectBottom(WidgetTester tester, num maxBottom) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.bottom, lessThanOrEqualTo(maxBottom.toDouble()));
}
