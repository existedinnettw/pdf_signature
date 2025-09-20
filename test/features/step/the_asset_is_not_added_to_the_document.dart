import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';

/// Usage: the asset is not added to the document
Future<void> theAssetIsNotAddedToTheDocument(WidgetTester tester) async {
  final container = TestWorld.container!;
  final library = container.read(signatureAssetRepositoryProvider);
  expect(
    library.isEmpty,
    true,
    reason: 'Invalid asset should not be added to library',
  );
}
