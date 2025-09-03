import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_page_area.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import 'package:pdf_signature/data/services/export_providers.dart';

void main() {
  testWidgets('placed signature stays attached on zoom (mock continuous)', (
    tester,
  ) async {
    const Size uiPageSize = Size(400, 560);

    // Test harness that exposes the ProviderContainer to mutate state
    late ProviderContainer container;
    Widget buildHarness({required double width}) {
      return ProviderScope(
        overrides: [
          // Force mock viewer for predictable layout; pageViewModeProvider already falls back to 'continuous'
          useMockViewerProvider.overrideWithValue(true),
        ],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return Directionality(
              textDirection: TextDirection.ltr,
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: width,
                      // Keep aspect ratio consistent with uiPageSize
                      child: PdfPageArea(
                        pageSize: uiPageSize,
                        onDragSignature: (_) {},
                        onResizeSignature: (_) {},
                        onConfirmSignature: () {},
                        onClearActiveOverlay: () {},
                        onSelectPlaced: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Initial pump at base width
    await tester.pumpWidget(buildHarness(width: 480));

    // Open sample and add a normalized placement to page 1
    container.read(pdfProvider.notifier).openSample();
    // One placement at (25% x, 50% y), size 10% x 10%
    container
        .read(pdfProvider.notifier)
        .addPlacement(
          page: 1,
          rect: const Rect.fromLTWH(0.25, 0.50, 0.10, 0.10),
        );

    await tester.pumpAndSettle();

    // Find the first page stack and the placed signature widget
    final pageStackFinder = find.byKey(const ValueKey('page_stack_1'));
    expect(pageStackFinder, findsOneWidget);

    final placedFinder = find.byKey(const Key('placed_signature_0'));
    expect(placedFinder, findsOneWidget);

    final pageBox = tester.getRect(pageStackFinder);
    final placedBox1 = tester.getRect(placedFinder);

    // Compute normalized position within the page container
    final relX1 = (placedBox1.left - pageBox.left) / pageBox.width;
    final relY1 = (placedBox1.top - pageBox.top) / pageBox.height;

    // Simulate zoom by doubling the available width
    await tester.pumpWidget(buildHarness(width: 960));
    // Maintain state across rebuild
    await tester.pumpAndSettle();

    final pageBox2 = tester.getRect(pageStackFinder);
    final placedBox2 = tester.getRect(placedFinder);

    final relX2 = (placedBox2.left - pageBox2.left) / pageBox2.width;
    final relY2 = (placedBox2.top - pageBox2.top) / pageBox2.height;

    // The relative position should stay approximately the same
    expect(
      (relX2 - relX1).abs() < 0.01,
      isTrue,
      reason: 'X should remain attached',
    );
    expect(
      (relY2 - relY1).abs() < 0.01,
      isTrue,
      reason: 'Y should remain attached',
    );
  });
}
