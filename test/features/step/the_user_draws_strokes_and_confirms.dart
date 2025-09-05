import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/signature_controller.dart';
import '_world.dart';

/// Usage: the user draws strokes and confirms
Future<void> theUserDrawsStrokesAndConfirms(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Simulate drawn signature bytes
  final bytes = Uint8List.fromList([1, 2, 3]);
  container.read(signatureProvider.notifier).setImageBytes(bytes);
}
