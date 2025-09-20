import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: a signature asset is created
Future<void> aSignatureAssetIsCreated(WidgetTester tester) async {
  final container = TestWorld.container!;
  final assets = container.read(signatureAssetRepositoryProvider);
  expect(assets, isNotEmpty);
  // The last added should be the drawn one
  final lastAsset = assets.last;
  expect(lastAsset.name, 'drawing');

  // Pump to ensure UI is updated
  await tester.pump();
}
