import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_repository.dart';
import '_world.dart';

/// Usage: the user clears the canvas
Future<void> theUserClearsTheCanvas(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(signatureProvider.notifier).setStrokes([]);
}
