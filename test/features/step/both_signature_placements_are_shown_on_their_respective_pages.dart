import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/pdf_repository.dart';
import '_world.dart';

/// Usage: both signature placements are shown on their respective pages
Future<void> bothSignaturePlacementsAreShownOnTheirRespectivePages(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  expect(pdf.placementsByPage[1], isNotEmpty);
  expect(pdf.placementsByPage[3], isNotEmpty);
}
