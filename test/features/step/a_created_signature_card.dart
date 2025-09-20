import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a created signature card
Future<void> aCreatedSignatureCard(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Create a dummy signature asset
  final asset = SignatureAsset(
    sigImage: img.Image(width: 1, height: 1),
    name: 'Test Card',
  );
  container
      .read(signatureAssetRepositoryProvider.notifier)
      .addImage(asset.sigImage, name: asset.name);
}
