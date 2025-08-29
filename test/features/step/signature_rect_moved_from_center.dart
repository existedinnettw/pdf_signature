import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature rect moved from center
Future<void> signatureRectMovedFromCenter(WidgetTester tester) async {
  final c = TestWorld.container!;
  final prev = TestWorld.prevCenter;
  final now = c.read(signatureProvider).rect!.center;
  expect(prev, isNotNull);
  expect(now, isNot(equals(prev)));
}
