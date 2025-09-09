import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import 'package:pdf_signature/data/model/model.dart';
import '_world.dart';

/// Usage: a created signature card
Future<void> aCreatedSignatureCard(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Create a dummy signature asset
  final asset = SignatureAsset(
    id: 'test_card',
    bytes: Uint8List(100),
    name: 'Test Card',
  );
  container.read(signatureLibraryProvider.notifier).state = [asset];
}
