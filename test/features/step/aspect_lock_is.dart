import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: aspect lock is {true}
Future<void> aspectLockIs(WidgetTester tester, bool value) async {
  final c = TestWorld.container!;
  // snapshot current aspect for later validation
  final r = c.read(signatureProvider).rect;
  if (r != null) {
    TestWorld.prevAspect = r.width / r.height;
  }
  c.read(signatureProvider.notifier).toggleAspect(value);
}
