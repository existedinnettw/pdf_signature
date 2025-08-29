import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: I set tiny signature image bytes
Future<void> iSetTinySignatureImageBytes(WidgetTester tester) async {
  final c = TestWorld.container!;
  final bytes = Uint8List.fromList([0, 1, 2, 3]);
  c.read(signatureProvider.notifier).setImageBytes(bytes);
}
