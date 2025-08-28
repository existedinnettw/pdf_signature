import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: the user enables background removal
Future<void> theUserEnablesBackgroundRemoval(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  container.read(signatureProvider.notifier).setBgRemoval(true);
}
