import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: I drag signature by {Offset(10000, -10000)}
Future<void> iDragSignatureBy(WidgetTester tester, Offset delta) async {
  final c = TestWorld.container!;
  c.read(signatureProvider.notifier).drag(delta);
}
