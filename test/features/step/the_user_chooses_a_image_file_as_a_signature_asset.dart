import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: the user chooses a image file as a signature asset
Future<void> theUserChoosesAImageFileAsASignatureAsset(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final image = img.Image(width: 1, height: 1);
  container
      .read(signatureAssetRepositoryProvider.notifier)
      .addImage(image, name: 'chosen.png');
}
