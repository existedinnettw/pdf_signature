import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: a default signature rect is placed
Future<void> aDefaultSignatureRectIsPlaced(WidgetTester tester) async {
  final c = TestWorld.container!;
  c.read(signatureProvider.notifier).placeDefaultRect();
  // remember center for movement checks
  TestWorld.prevCenter = c.read(signatureProvider).rect!.center;
}
