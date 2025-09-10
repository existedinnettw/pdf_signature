import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: a signature placement appears on the page based on the signature card
Future<void> aSignaturePlacementAppearsOnThePageBasedOnTheSignatureCard(
  WidgetTester tester,
) async {
  final container = TestWorld.container!;
  final pdf = container.read(documentRepositoryProvider);
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(
    placements.isNotEmpty,
    true,
    reason: 'A signature placement should appear on the page',
  );
}
