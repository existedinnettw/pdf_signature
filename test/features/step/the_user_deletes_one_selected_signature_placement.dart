import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user deletes one selected signature placement
Future<void> theUserDeletesOneSelectedSignaturePlacement(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final currentPage = container.read(pdfViewModelProvider);
  final placements = container
      .read(documentRepositoryProvider.notifier)
      .placementsOn(currentPage);
  if (placements.isNotEmpty) {
    container
        .read(documentRepositoryProvider.notifier)
        .removePlacement(page: currentPage, index: 0);
  }
}
