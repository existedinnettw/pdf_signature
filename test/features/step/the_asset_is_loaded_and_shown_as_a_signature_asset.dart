import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/signature/view_model/signature_library.dart';
import '_world.dart';

/// Usage: the asset is loaded and shown as a signature asset
Future<void> theAssetIsLoadedAndShownAsASignatureAsset(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final library = container.read(signatureLibraryProvider);
  expect(
    library.isNotEmpty,
    true,
    reason: 'Asset should be loaded and shown in library',
  );
}
