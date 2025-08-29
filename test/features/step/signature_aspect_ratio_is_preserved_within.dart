import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: signature aspect ratio is preserved within {0.05}
Future<void> signatureAspectRatioIsPreservedWithin(
  WidgetTester tester,
  num tolerance,
) async {
  final c = TestWorld.container!;
  final r = c.read(signatureProvider).rect!;
  final before = TestWorld.prevAspect;
  if (before == null) {
    // save and pass
    TestWorld.prevAspect = r.width / r.height;
    return;
  }
  final after = r.width / r.height;
  expect((after - before).abs(), lessThanOrEqualTo(tolerance.toDouble()));
}
