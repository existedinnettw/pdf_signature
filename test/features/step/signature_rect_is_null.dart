import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: signature rect is null
Future<void> signatureRectIsNull(WidgetTester tester) async {
  final c = TestWorld.container!;
  expect(c.read(signatureProvider).rect, isNull);
}
