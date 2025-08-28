import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: I set signature image bytes {Uint8List.fromList([0, 1, 2])}
Future<void> iSetSignatureImageBytes(WidgetTester tester, dynamic value) async {
  final c = TestWorld.container!;
  final bytes = value as Uint8List;
  c.read(signatureProvider.notifier).setImageBytes(bytes);
}
