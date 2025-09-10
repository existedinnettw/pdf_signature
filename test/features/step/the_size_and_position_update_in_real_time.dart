import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the size and position update in real time
Future<void> theSizeAndPositionUpdateInRealTime(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final pdf = container.read(documentRepositoryProvider);

  final placements = pdf.placementsByPage[pdf.currentPage] ?? [];
  if (placements.isNotEmpty) {
    final currentRect = placements[0].rect;
    expect(currentRect.center, isNot(TestWorld.prevCenter));
  }
}
