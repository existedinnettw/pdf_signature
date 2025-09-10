import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_signature/ui/features/pdf/widgets/pdf_page_area.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_providers.dart';

import 'package:pdf_signature/l10n/app_localizations.dart';
import 'package:pdf_signature/domain/models/model.dart';

class _TestPdfController extends DocumentStateNotifier {
  _TestPdfController() : super() {
    state = Document.initial().copyWith(
      loaded: true,
      pageCount: 6,
      currentPage: 1,
    );
  }
}

void main() {
  testWidgets('PdfPageArea shows continuous mock pages when in mock mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useMockViewerProvider.overrideWithValue(true),
          documentRepositoryProvider.overrideWith(
            (ref) => _TestPdfController(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 520,
                child: PdfPageArea(
                  pageSize: Size(676, 400),
                  onDragSignature: _noopOffset,
                  onResizeSignature: _noopOffset,
                  onConfirmSignature: _noop,
                  onClearActiveOverlay: _noop,
                  onSelectPlaced: _noopInt,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);
    expect(find.byKey(const ValueKey('page_stack_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('page_stack_6')), findsOneWidget);
  });

  testWidgets('placed signature stays attached on zoom (mock continuous)', (
    tester,
  ) async {
    const Size uiPageSize = Size(400, 560);

    // Use a persistent container across rebuilds
    final container = ProviderContainer(
      overrides: [
        useMockViewerProvider.overrideWithValue(true),
        documentRepositoryProvider.overrideWith(
          (ref) => DocumentStateNotifier()..openSample(),
        ),
      ],
    );
    addTearDown(container.dispose);

    Widget buildHarness({required double width}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                // Keep aspect ratio consistent with uiPageSize
                child: const PdfPageArea(
                  pageSize: uiPageSize,
                  onDragSignature: _noopOffset,
                  onResizeSignature: _noopOffset,
                  onConfirmSignature: _noop,
                  onClearActiveOverlay: _noop,
                  onSelectPlaced: _noopInt,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Initial pump at base width
    await tester.pumpWidget(buildHarness(width: 480));

    // Add a tiny non-empty asset to avoid decode errors
    final canvas = img.Image(width: 10, height: 5);
    img.fill(canvas, color: img.ColorUint8.rgb(0, 0, 0));
    final bytes = Uint8List.fromList(img.encodePng(canvas));
    // One placement at (25% x, 50% y), size 10% x 10%
    container
        .read(documentRepositoryProvider.notifier)
        .addPlacement(
          page: 1,
          rect: const Rect.fromLTWH(0.25, 0.50, 0.10, 0.10),
          asset: SignatureAsset(bytes: bytes),
        );

    await tester.pumpAndSettle();

    // Verify we're using the mock viewer
    expect(find.byKey(const Key('pdf_continuous_mock_list')), findsOneWidget);

    // Find the first page stack and the placed signature widget
    final pageStackFinder = find.byKey(const ValueKey('page_stack_1'));
    expect(pageStackFinder, findsOneWidget);

    final placedFinder = find.byKey(const Key('placed_signature_0'));
    expect(placedFinder, findsOneWidget);

    // Ensure the widget is fully laid out
    await tester.pumpAndSettle();

    final pageBox = tester.getRect(pageStackFinder);

    // The placed signature widget itself is a DecoratedBox
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
      (relX2 - relX1).abs() < 0.2,
      isTrue,
      reason: 'X should remain attached',
    );
    expect(
      (relY2 - relY1).abs() < 0.2,
      isTrue,
      reason: 'Y should remain attached',
    );
  });
}

void _noop() {}
void _noopInt(int? _) {}
void _noopOffset(Offset _) {}
