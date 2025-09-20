import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: the user chooses a signature asset to created a signature card
Future<void> theUserChoosesASignatureAssetToCreatedASignatureCard(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container
      .read(signatureAssetRepositoryProvider.notifier)
      .addImage(img.Image(width: 1, height: 1), name: 'card.png');
}
