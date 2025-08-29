import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: I resize signature by {Offset(1000, 1000)}
Future<void> iResizeSignatureBy(WidgetTester tester, Offset delta) async {
  final c = TestWorld.container!;
  c.read(signatureProvider.notifier).resize(delta);
}
