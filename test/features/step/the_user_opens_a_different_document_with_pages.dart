import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import 'package:pdf_signature/domain/models/model.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user opens a different document with {3} pages
Future<void> theUserOpensADifferentDocumentWithPages(
  WidgetTester tester,
  num param1,
) async {
  final pageCount = param1.toInt();
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;

  // Simulate "open a different document": reset placements and set page count.
  container
      .read(documentRepositoryProvider.notifier)
      .openPickedWithPageCount(pageCount: pageCount);
  // Ensure there are 2 signature cards available as per scenario.
  final cards = container.read(signatureCardRepositoryProvider);
  if (cards.length < 2) {
    final notifier = container.read(signatureCardRepositoryProvider.notifier);
    while (container.read(signatureCardRepositoryProvider).length < 2) {
      notifier.add(
        SignatureCard(
          asset: SignatureAsset(
            sigImage: img.Image(width: 1, height: 1),
            name: 'sig.png',
          ),
          rotationDeg: 0,
          graphicAdjust: const GraphicAdjust(),
        ),
      );
    }
  }
  // Moving to a new document should show page 1.
  container.read(pdfViewModelProvider).currentPage = 1;
  await tester.pumpAndSettle();
}
