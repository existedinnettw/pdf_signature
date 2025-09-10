import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: each signature placement can be dragged and resized independently
Future<void> eachSignaturePlacementCanBeDraggedAndResizedIndependently(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);
  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  expect(placements.length, greaterThan(1));
}
