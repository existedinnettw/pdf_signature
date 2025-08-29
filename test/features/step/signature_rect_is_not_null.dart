import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature rect is not null
Future<void> signatureRectIsNotNull(WidgetTester tester) async {
  final c = TestWorld.container!;
  expect(c.read(signatureProvider).rect, isNotNull);
}
