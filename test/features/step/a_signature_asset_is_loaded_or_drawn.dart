import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import '_world.dart';

/// Usage: a signature asset is loaded or drawn
Future<void> aSignatureAssetIsLoadedOrDrawn(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  container.read(signatureAssetRepositoryProvider.notifier).state = [];
  container.read(documentRepositoryProvider.notifier).state =
      Document.initial();
  container.read(signatureCardRepositoryProvider.notifier).state = [
    SignatureCard.initial(),
  ];
  final image = img.Image(width: 1, height: 1);
  container
      .read(signatureAssetRepositoryProvider.notifier)
      .addImage(image, name: 'test.png');
  await tester.pump();
}
