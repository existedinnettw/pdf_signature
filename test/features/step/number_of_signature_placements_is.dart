import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';
import '_world.dart';

/// Usage: number of signature placements is {0}
Future<void> numberOfSignaturePlacementsIs(
  WidgetTester tester,
  num param1,
) async {
  final expected = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  final doc = c.read(documentRepositoryProvider);
  final total = doc.placementsByPage.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );
  expect(total, expected);
  // If we had previous placements recorded, ensure they were non-zero to
  // validate that a reset actually happened when opening a different doc.
  if (TestWorld.prevPlacementsCount != null &&
      TestWorld.prevPlacementsCount!.isNotEmpty) {
    final prevTotal = TestWorld.prevPlacementsCount!.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );
    expect(prevTotal, greaterThan(0));
  }
  // Also verify that signature cards still exist (persistence across open).
  final cards = c.read(signatureCardRepositoryProvider);
  expect(cards.length, greaterThanOrEqualTo(1));
}
