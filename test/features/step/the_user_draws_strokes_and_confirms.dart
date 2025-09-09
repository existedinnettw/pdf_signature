import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import '_world.dart';

/// Usage: the user draws strokes and confirms
Future<void> theUserDrawsStrokesAndConfirms(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Simulate drawn signature bytes
  final bytes = Uint8List.fromList([1, 2, 3]);
  container.read(signatureProvider.notifier).setImageBytes(bytes);
}
