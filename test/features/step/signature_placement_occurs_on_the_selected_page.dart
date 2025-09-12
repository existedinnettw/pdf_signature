import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_asset_repository.dart';
import '_world.dart';
import 'dart:ui';

/// Usage: signature placement occurs on the selected page
/// Simplified: directly adds a placement to page 1 if none exist yet.
Future<void> signaturePlacementOccursOnTheSelectedPage(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final repo = container.read(documentRepositoryProvider.notifier);
  final state = container.read(documentRepositoryProvider);
  final page = 1;
  if ((state.placementsByPage[page] ?? const []).isEmpty) {
    final assets = container.read(signatureAssetRepositoryProvider);
    final asset = assets.isNotEmpty ? assets.last : null;
    repo.addPlacement(
      page: page,
      rect: const Rect.fromLTWH(0.1, 0.1, 0.2, 0.1),
      asset: asset,
    );
  }
  await tester.pumpAndSettle();
  final updated = container.read(documentRepositoryProvider);
  expect(updated.placementsByPage[page], isNotEmpty);
}
