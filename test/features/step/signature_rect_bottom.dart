import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: signature rect bottom <= {560}
Future<void> signatureRectBottom(WidgetTester tester, num maxBottom) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  expect(r.bottom, lessThanOrEqualTo(maxBottom.toDouble()));
}
