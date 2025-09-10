import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'helpers.dart';

void main() {
  testWidgets(
    'Active overlay appears when signature asset exists and can be confirmed',
    (tester) async {
      await pumpWithOpenPdfAndSig(tester);

      // Active overlay should be visible on page 1 in the mock viewer
      final overlay = find.byKey(const Key('signature_overlay'));
      expect(overlay, findsOneWidget);

      // Simulate confirm by adding a placement directly via controller for determinism
      final ctx = tester.element(find.byType(PdfSignatureHomePage));
      final container = ProviderScope.containerOf(ctx);
      container
          .read(documentRepositoryProvider.notifier)
          .addPlacement(page: 1, rect: const Rect.fromLTWH(200, 200, 120, 40));
      await tester.pumpAndSettle();

      // Now a placed signature should exist
      final placed = find.byWidgetPredicate(
        (w) => w.key?.toString().contains('placed_signature_') == true,
      );
      expect(placed, findsWidgets);
    },
  );
}
